import { GoogleGenAI } from '@google/genai';
import dotenv from 'dotenv';
import { ASSISTANT_SYSTEM_INSTRUCTION } from './assistant_system_instruction.js';

dotenv.config();

// Initialize the Google Gen AI SDK client
// It will load the GEMINI_API_KEY from environment or process variables
const apiKey = process.env.GEMINI_API_KEY;
const hasApiKey = apiKey && apiKey !== 'YOUR_GEMINI_API_KEY_HERE';

const ai = hasApiKey ? new GoogleGenAI({ apiKey }) : null;

// The model requested in specifications: "gemini-3-flash-preview" (or fallback to "gemini-2.5-flash")
const VISION_MODEL = 'gemini-2.5-flash';
const CHAT_MODEL = 'gemini-2.5-flash';

/**
 * Utility to convert binary buffer to base64 inline data format for Gemini API.
 */
function bufferToGenerativePart(buffer, mimeType = 'image/jpeg') {
  return {
    inlineData: {
      data: buffer.toString('base64'),
      mimeType,
    },
  };
}

function isValidInputVoltage(value) {
  if (value == null) return false;
  const text = String(value).trim();
  if (!text || text.toLowerCase() === 'unknown' || text.toLowerCase() === 'n/a') {
    return false;
  }
  return /\d+\s*v/i.test(text);
}

/**
 * 1. SPECIFICATION PLATE OCR
 * Extracts Brand, Model, Serial Number, Input Voltage, and Output Current.
 */
export async function processOcr(imageBuffer) {
  if (!ai) {
    console.log('[Gemini Services] Mocking processOcr (Label Extraction)...');
    return {
      success: true,
      brand: 'Tesla',
      modelName: 'Tesla Wall Connector Gen 3',
      serialNumber: 'TWC-2024-A8F3E2',
      inputVoltage: '230V AC',
      outputCurrent: '32A',
    };
  }

  try {
    const response = await ai.models.generateContent({
      model: VISION_MODEL,
      contents: [
        bufferToGenerativePart(imageBuffer),
        `You are an OCR engine. Extract ANY text you can read from this specification label plate.
Try to identify:
- Any model number or model name
- Any serial number (look for S/N, SN, Serial No, or long alphanumeric strings)
- Any voltage values (look for V, VAC, VDC) (e.g. 230V AC, 400V AC, 110-240V)
- Any current values (look for A, Amps) (e.g. 32A, 16A)

NOTE: Do NOT guess the brand — it will be detected separately.
Be generous — if you see text that COULD be a serial number or model, extract it.
Do not return null unless the field is completely absent or unreadable.`,
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            modelName:     { type: 'STRING', description: 'Commercial model name' },
            serialNumber:  { type: 'STRING', description: 'Product serial number' },
            inputVoltage:  { type: 'STRING', description: 'Input voltage rating (e.g. 230V AC, 400V 3-phase)' },
            outputCurrent: { type: 'STRING', description: 'Output current in amps (e.g. 32A, 16A)' },
          },
          required: [],
        },
      },
    });

    const data = JSON.parse(response.text.trim());

    // Log the extracted specs clearly
    console.log('[OCR Result] Gemini extraction complete:');
    console.log(`  Brand:          ${data.brand || '(not extracted)'}`);
    console.log(`  Model:          ${data.modelName || '(not extracted)'}`);
    console.log(`  Serial Number:  ${data.serialNumber || '(not extracted)'}`);
    console.log(`  Input Voltage:  ${data.inputVoltage || '(not extracted)'}`);
    console.log(`  Output Current: ${data.outputCurrent || '(not extracted)'}`);

    // Count how many fields were successfully extracted (not null/undefined)
    const extractedCount = [
      data.modelName,
      data.serialNumber,
      data.inputVoltage,
      data.outputCurrent
    ].filter(field => field != null).length;

    console.log(`  Fields extracted: ${extractedCount}/5`);
 
    const hasKeyFields = Boolean(
      (data.serialNumber && String(data.serialNumber).trim()) ||
      (data.modelName && String(data.modelName).trim()),
    );

    if (!hasKeyFields) {
      console.warn('[OCR Result] No model or serial number could be read');
      return {
        success: false,
        brand: data.brand || 'unknown',
        modelName: data.modelName || 'unknown',
        serialNumber: data.serialNumber || 'unknown',
        inputVoltage: data.inputVoltage || 'unknown',
        outputCurrent: data.outputCurrent || 'unknown',
        partialExtraction: extractedCount > 0,
        reason: extractedCount > 0
          ? `Only ${extractedCount} field(s) readable. Need a clearer view of the model or serial number.`
          : 'Could not read any text from the plate. Move closer, improve lighting, and hold steady.',
      };
    }

    if (!isValidInputVoltage(data.inputVoltage)) {
      console.warn('[OCR Result] Input voltage missing or unreadable');
      return {
        success: false,
        brand: data.brand || 'unknown',
        modelName: data.modelName || 'unknown',
        serialNumber: data.serialNumber || 'unknown',
        inputVoltage: data.inputVoltage || 'unknown',
        outputCurrent: data.outputCurrent || 'unknown',
        partialExtraction: true,
        reason:
          'Could not read input voltage from the spec plate. Retake a clearer photo showing the voltage rating (e.g. 230V AC).',
      };
    }

    const partialExtraction = extractedCount < 4;
    if (partialExtraction) {
      console.warn(`[OCR Result] Partial read (${extractedCount}/4 fields); accepting model/serial`);
    }

    return {
      success: true,
      brand: data.brand || 'unknown',
      modelName: data.modelName || 'unknown',
      serialNumber: data.serialNumber || 'unknown',
      inputVoltage: data.inputVoltage || 'unknown',
      outputCurrent: data.outputCurrent || 'unknown',
      partialExtraction,
    };
  } catch (error) {
    const message = error.message || String(error);
    console.error('[Gemini API Error] processOcr failed:', message);

    if (message.includes('429') || message.includes('RESOURCE_EXHAUSTED') || message.includes('quota')) {
      return {
        success: false,
        brand: 'unknown',
        modelName: 'unknown',
        serialNumber: 'unknown',
        inputVoltage: 'unknown',
        outputCurrent: 'unknown',
        quotaExceeded: true,
        reason: 'Gemini API daily quota exceeded. Wait ~1 minute and retry, or upgrade your API plan.',
      };
    }

    throw error;
  }
}

/**
 * 3. AI CONVERSATIONAL ASSISTANT
 * Answers technical questions about EV chargers and diagnostics.
 */
function buildChatContents(history, message) {
  const contents = [];

  if (history && Array.isArray(history)) {
    let startIndex = 0;
    while (startIndex < history.length && !history[startIndex]?.isUser) {
      startIndex += 1;
    }

    for (let i = startIndex; i < history.length; i += 1) {
      const text = (history[i]?.text ?? '').trim();
      if (!text) continue;

      contents.push({
        role: history[i].isUser ? 'user' : 'model',
        parts: [{ text }],
      });
    }
  }

  contents.push({
    role: 'user',
    parts: [{ text: message }],
  });

  return contents;
}

export async function chatAssistant(history, message, diagnosticState) {
  if (!ai) {
    console.log('[Gemini Services] API Key Missing on Server...');
    return {
      success: true,
      reply: "⚠️ **Gemini API Key Missing on Server**\n\nThe EVision Diagnostics proxy server is running, but the `GEMINI_API_KEY` has not been configured in the server's `.env` file.\n\nTo enable real-time AI responses:\n1. Open the `/server` folder on your computer.\n2. Copy `.env.example` to a new file named `.env`.\n3. Add your Gemini API key (from https://aistudio.google.com/) to the `GEMINI_API_KEY` variable.\n4. Restart the server (`npm start`)."
    };
  }

  try {
    const response = await ai.models.generateContent({
      model: CHAT_MODEL,
      contents: buildChatContents(history, message),
      config: {
        systemInstruction: ASSISTANT_SYSTEM_INSTRUCTION,
      },
    });

    const reply = response.text?.trim();
    if (!reply) {
      throw new Error('Gemini returned an empty response');
    }

    return {
      success: true,
      reply,
    };
  } catch (error) {
    console.error('[Gemini API Error] chatAssistant failed:', error);
    throw error;
  }
}

