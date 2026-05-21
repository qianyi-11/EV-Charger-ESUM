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

/**
 * 1. CHECK IMAGE SHARPNESS
 * Validates ahead of time if the picture captured is sharp and clear.
 */
export async function checkBlur(imageBuffer) {
  if (!ai) {
    console.log('[Gemini Services] Mocking checkBlur (Sharpness Verification)...');
    return { isSharp: true };
  }

  try {
    const response = await ai.models.generateContent({
      model: VISION_MODEL,
      contents: [
        bufferToGenerativePart(imageBuffer),
        'Analyze this image of an electrical component. Is the image clear, in focus, and sharp enough for technical text extraction or object recognition? Return a strict JSON response indicating whether it is sharp.',
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            isSharp: {
              type: 'BOOLEAN',
              description: 'True if the image is sharp and legible; False if blurry, shaky, or out of focus.',
            },
            reason: {
              type: 'STRING',
              description: 'Short explanation of clarity score.',
            },
          },
          required: ['isSharp'],
        },
      },
    });

    return JSON.parse(response.text.trim());
  } catch (error) {
    console.error('[Gemini API Error] checkBlur failed:', error);
    throw error;
  }
}

/**
 * 2. SPECIFICATION PLATE OCR
 * Extracts Brand, Model, Serial Number, and Max Power rating.
 */
export async function processOcr(imageBuffer) {
  if (!ai) {
    console.log('[Gemini Services] Mocking processOcr (Label Extraction)...');
    return {
      success: true,
      brand: 'Tesla',
      modelName: 'Tesla Wall Connector Gen 3',
      serialNumber: 'TWC-2024-A8F3E2',
      powerRatingKw: 22.0,
      confidence: 0.98,
    };
  }

  try {
    const response = await ai.models.generateContent({
      model: VISION_MODEL,
      contents: [
        bufferToGenerativePart(imageBuffer),
        'You are an expert industrial OCR engine specialized in EV Charging equipment. Extract the manufacturer brand, exact model name, serial number, and maximum power rating in kW from this charger specification label plate.',
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            brand: { type: 'STRING', description: 'Manufacturer name (e.g. Tesla, Abb, Wallbox)' },
            modelName: { type: 'STRING', description: 'Commercial model name' },
            serialNumber: { type: 'STRING', description: 'Product Serial Number identifier' },
            powerRatingKw: { type: 'NUMBER', description: 'Max power capacity in kilowatts' },
            confidence: { type: 'NUMBER', description: 'Confidence level from 0.0 to 1.0' },
          },
          required: ['brand', 'modelName', 'serialNumber', 'powerRatingKw', 'confidence'],
        },
      },
    });

    const data = JSON.parse(response.text.trim());
    return {
      success: true,
      ...data,
    };
  } catch (error) {
    console.error('[Gemini API Error] processOcr failed:', error);
    throw error;
  }
}

/**
 * 3. DISTRIBUTION BOARD COMPLIANCE AUDIT
 * Assesses circuit breaker (MCB / RCCB) ratings and trip conditions.
 */
export async function analyzeEvdb(imageBuffer) {
  if (!ai) {
    console.log('[Gemini Services] Mocking analyzeEvdb (Breaker Verification)...');
    return {
      success: true,
      isCompliant: false,
      detectedMcbRating: '16A',
      detectedRccbRating: 'Type A',
      confidence: 0.94,
      errorMessage: 'MCB current rating is insufficient. EV charger requires 32A or 40A safety protection.',
    };
  }

  try {
    const response = await ai.models.generateContent({
      model: VISION_MODEL,
      contents: [
        bufferToGenerativePart(imageBuffer),
        'You are an electrical inspector AI. Evaluate this Electric Vehicle Distribution Board (EVDB). Extract the current rating in Amps of the main miniature circuit breaker (MCB) and determine the type of Residual Current Device (RCCB). Verify if they comply with the 40A MCB load safety threshold and indicate any tripped or missing breakers.',
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            isCompliant: { type: 'BOOLEAN', description: 'True if MCB is 32A/40A and RCCB is fully compliant' },
            detectedMcbRating: { type: 'STRING', description: 'Amperage rating of MCB (e.g. 16A, 32A, 40A)' },
            detectedRccbRating: { type: 'STRING', description: 'Detected RCCB rating/type' },
            confidence: { type: 'NUMBER', description: 'Confidence score from 0.0 to 1.0' },
            errorMessage: { type: 'STRING', description: 'Detailed warning message if non-compliant, otherwise empty' },
          },
          required: ['isCompliant', 'detectedMcbRating', 'detectedRccbRating', 'confidence'],
        },
      },
    });

    const data = JSON.parse(response.text.trim());
    return {
      success: true,
      ...data,
    };
  } catch (error) {
    console.error('[Gemini API Error] analyzeEvdb failed:', error);
    throw error;
  }
}

/**
 * 4. GATEWAY STATUS LED TESTING
 * Classifies status LED colors and blinking frequencies.
 */
export async function detectGateway(imageBuffer) {
  if (!ai) {
    console.log('[Gemini Services] Mocking detectGateway (LED Color Classification)...');
    return {
      success: true,
      chargerDetected: true,
      lightDetected: true,
      lightColor: 'RED',
      confidence: 0.96,
    };
  }

  try {
    const response = await ai.models.generateContent({
      model: VISION_MODEL,
      contents: [
        bufferToGenerativePart(imageBuffer),
        'Identify the front status indicator lights of the EV charger in this frame. Detect if a status LED is ON or OFF. If ON, classify the color (RED, GREEN, BLUE).',
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            chargerDetected: { type: 'BOOLEAN', description: 'True if an EV charger body is recognized' },
            lightDetected: { type: 'BOOLEAN', description: 'True if an active LED light is found' },
            lightColor: { type: 'STRING', description: 'Light color: RED, GREEN, BLUE, or OFF' },
            confidence: { type: 'NUMBER', description: 'Classification confidence from 0.0 to 1.0' },
          },
          required: ['chargerDetected', 'lightDetected', 'lightColor', 'confidence'],
        },
      },
    });

    const data = JSON.parse(response.text.trim());
    return {
      success: true,
      ...data,
    };
  } catch (error) {
    console.error('[Gemini API Error] detectGateway failed:', error);
    throw error;
  }
}

/**
 * 5. ROTARY ISOLATOR SWITCH CLASSIFIER
 * Assesses if the rotary safety toggle is turned ON or OFF.
 */
export async function analyzeIsolator(imageBuffer) {
  if (!ai) {
    console.log('[Gemini Services] Mocking analyzeIsolator...');
    return {
      success: true,
      isSwitchOn: false,
      confidence: 0.97,
    };
  }

  try {
    const response = await ai.models.generateContent({
      model: VISION_MODEL,
      contents: [
        bufferToGenerativePart(imageBuffer),
        'Examine this heavy-duty rotary isolator switch. Classify if the rotary selector dial is aligned with the ON (Healthy) indicator or the OFF (Isolated/Fault) position.',
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            isSwitchOn: { type: 'BOOLEAN', description: 'True if switch is ON, False if switch is OFF' },
            confidence: { type: 'NUMBER', description: 'Classification score from 0.0 to 1.0' },
          },
          required: ['isSwitchOn', 'confidence'],
        },
      },
    });

    const data = JSON.parse(response.text.trim());
    return {
      success: true,
      ...data,
    };
  } catch (error) {
    console.error('[Gemini API Error] analyzeIsolator failed:', error);
    throw error;
  }
}

/**
 * 6. AI CONVERSATIONAL ASSISTANT
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

export async function chatAssistant(history, message) {
  if (!ai) {
    console.log('[Gemini Services] Mocking chatAssistant response...');
    return {
      success: true,
      reply: "I'm running in offline simulated mode. If this were a live deployment, I would query the Gemini-2.5-Flash model directly using your configured API key. Please check your cable connections and ensure the rotary isolator switch is flipped ON."
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

