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
 * 3. DISTRIBUTION BOARD COMPLIANCE AUDIT
 * Assesses circuit breaker (MCB / RCCB) ratings and trip conditions.
 */
export async function analyzeEvdb(imageBuffer, specsContext = {}) {
  const { inputVoltage, outputCurrent } = specsContext;
  
  const specsPrompt = (inputVoltage || outputCurrent)
    ? `
The charger spec label was previously scanned with these values:
- Input Voltage: ${inputVoltage || 'unknown'}
- Output Current: ${outputCurrent || 'unknown'}

Compare these against what you read from the EVDB panel.
Flag any mismatches as compliance issues.
`
    : '';

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
        `You are an electrical inspector AI. Evaluate this Electric Vehicle Distribution Board (EVDB).
${specsPrompt}
Extract the current rating in Amps of the main miniature circuit breaker (MCB) and determine the type of Residual Current Device (RCCB). 
Verify if they comply with the 40A MCB load safety threshold and indicate any tripped or missing breakers.
Report any discrepancies between charger specs and EVDB configuration.`,
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
            specsMatched: { type: 'BOOLEAN', description: 'True if EVDB matches the charger specs (if provided)' },
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

export async function chatAssistant(history, message, diagnosticState) {
  if (!ai) {
    console.log('[Gemini Services] API Key Missing on Server...');
    return {
      success: true,
      reply: "⚠️ **Gemini API Key Missing on Server**\n\nThe EVision Diagnostics proxy server is running, but the `GEMINI_API_KEY` has not been configured in the server's `.env` file.\n\nTo enable real-time AI responses:\n1. Open the `/server` folder on your computer.\n2. Copy `.env.example` to a new file named `.env`.\n3. Add your Gemini API key (from https://aistudio.google.com/) to the `GEMINI_API_KEY` variable.\n4. Restart the server (`npm start`)."
    };
  }

  try {
    let systemInstruction = ASSISTANT_SYSTEM_INSTRUCTION;

    if (diagnosticState) {
      const { ocrCompleted, recentActivity, chargerModel, serialNumber, selectedBranch, isIsolatorOn, isEvdbOk, blinksCounted, targetErrorCode } = diagnosticState;
      const hasNoScans = !ocrCompleted && (!recentActivity || recentActivity.length === 0);
      const activeError = (recentActivity && recentActivity.length > 0) ? recentActivity[0].code : 'none';

      if (hasNoScans) {
        systemInstruction += `\n\n--- CRITICAL DYNAMIC DEVICE CONTEXT ---
⚠️ IMPORTANT: There is NO active scan history or diagnostic data currently available for this charger.
If the user asks about dangerous conditions, continuing charging, how to fix, or diagnostic status, you MUST politely state:
"🔌 No Scan History Found. I currently do not see any active diagnostic telemetry or scan history for your charger. Therefore, I cannot determine if there is a safety risk, if it is safe to charge, or how to resolve any issues. Please go back to the Dashboard and tap [Start Diagnosis] to scan your charger status panel or specification plate so that I can provide real-time guidance."
Do NOT output any simulated RCCB/Error 8 instructions when there is no scan history.`;
      } else {
        systemInstruction += `\n\n--- CRITICAL DYNAMIC DEVICE CONTEXT ---
ACTIVE TELEMETRY CONTEXT:
- Charger Model: ${chargerModel || 'Unknown Charger'}
- Serial Number: ${serialNumber || 'Unknown Serial'}
- Active Diagnosed Fault Code: ${activeError}
- Current Branch: Branch ${selectedBranch}
- Isolator Switch State: ${isIsolatorOn ? 'ON' : 'OFF'}
- EVDB Specification Status: ${isEvdbOk ? 'Incompatible Board/Breaker Detected' : 'Board spec checks passed'}
- Blinks Counted: ${blinksCounted}

You MUST tailor your diagnostic responses strictly and dynamically to the active fault code: ${activeError}.
- If active fault code is 'power-cut': Clearly explain that the Isolator Switch is OFF and must be turned ON.
- If active fault code is 'protection-issue': Explain that the EV Distribution Board (EVDB) breaker capacity/MCB specification is incorrect/wrong board spec. Advise them a technician is auto-contacted, and DO NOT touch the board.
- If active fault code is 'blink-6': Explain that there is a Grounding/PE open-circuit fault. Advise keeping clear and that a technician is on the way.
- If active fault code is 'blink-7': Explain that the Emergency Stop (E-Stop) button is pressed. Advise twisting it clockwise to reset.
- If active fault code is 'blink-8': Explain that there is an RCCB earth leakage fault. Advise unplugging and checking for damage/water.
- If active fault code is 'blink-9': Explain that there is a microcontroller/control loop hang. Advise power cycling the main isolator switch.
- If active fault code is 'charger-issue': Explain that a general internal overtemperature or cooling fan hardware fault is active.
Never output fake RCCB (Error 8) information if the active scanned error code is different.`;
      }
    }

    const response = await ai.models.generateContent({
      model: CHAT_MODEL,
      contents: buildChatContents(history, message),
      config: {
        systemInstruction,
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

