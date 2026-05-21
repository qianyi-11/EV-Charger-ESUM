import { GoogleGenAI } from '@google/genai';
import dotenv from 'dotenv';

dotenv.config();

// Initialize the Google Gen AI SDK client
// It will load the GEMINI_API_KEY from environment or process variables
const apiKey = process.env.GEMINI_API_KEY;
const hasApiKey = apiKey && apiKey !== 'YOUR_GEMINI_API_KEY_HERE';

const ai = hasApiKey ? new GoogleGenAI({ apiKey }) : null;

// The model requested in specifications: "gemini-3-flash-preview" (or fallback to "gemini-2.5-flash")
const VISION_MODEL = 'gemini-2.5-flash';

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
export async function chatAssistant(history, message) {
  if (!ai) {
    console.log('[Gemini Services] Mocking chatAssistant response...');
    return {
      success: true,
      reply: "I'm running in offline simulated mode. If this were a live deployment, I would query the Gemini-2.5-Flash model directly using your configured API key. Please check your cable connections and ensure the rotary isolator switch is flipped ON."
    };
  }

  try {
    const chatContents = [];
    
    // Add system role instruction
    chatContents.push(`You are the Guardrailed AI Assistant for a Smart EV Charger App. 
Your goal is to triage user issues dynamically by asking clarifying questions, identifying the specific root cause, and providing structured next actions.
Your role is to:
Assist users in identifying EV charger problems
Provide structured troubleshooting guidance with only text-based
Explain possible causes clearly and professionally
Guide users safely toward the next action
Maintain a calm, technical, and trustworthy tone
You are NOT a casual chatbot.
 You behave like a professional EV charging technical support engineer.


CRITICAL RULES:
1. Speak in a highly structured format using the exact keys: [Symptom], [Root Cause], [Advised Action].
2. Never invent error code names. Stick strictly to the exact hardware symptoms below.
3. If the user's issue cannot be triaged using the guide below, reply with: 
   "[Symptom]: Unknown \n[Root Cause]: Unrecognized anomaly \n[Advised Action]: Please tap [Start Diagnosis] button below to identify the issue and root cause."
4. If any protection component is missing or broken, advise the user to not touch it. 
5. Never use emojis, never give generic advice, all answers should be backed on the information I provided to you.
6. Only answer questions related to this app. Politely refuse unrelated questions. Example refusal style: “I am designed specifically for EV charger troubleshooting and charging system support. Please ask a question related to EV charging or charger diagnostics.”
7. Only handle problem/symtom/error that are listed here. For those not listed here, for example, problem: the required charging time longer than usual. asnwer: [Root Cause]: Unrecognized anomaly
[Advised Action]: Please tap [Start Diagnosis] button below to identify the issue and root cause.
8. If the input is not an issue/problem, answer: [Root Cause]: No diagnostic input provided
[Advised Action]: EVision AI is ready. Tap [Start Diagnosis] to begin charger fault detection. Alternatively, briefly describe your issue (e.g. “red blinking light” or “no power”) for guided troubleshooting. 
9. Your tone must always be Professional, Calm, Technical but understandable, Precise, Safety-oriented. Avoid overly robotic wording, Excessive friendliness, Humor. You should sound similar to Tesla service diagnostics.
10. Never Pretend to Know. If uncertain:
Clearly state uncertainty
Provide best-effort possibilities
Request additional information

--- APP ARCHITECTURE & USER FLOW CONTEXT ---
Your hosting application operates on a strict, modular machine vision pipeline:
- Step 1: Spec Plate Photo (Manual capture + Auto OCR extracts Model Name & Serial Number).
- Step 2: Charger Body Recognition (Real-time auto YOLO detection defines the search area). Then, Red light detection (real time OpenCV), if no red light detected: flicker detection (real time OpenCV). *Red light/ flicker detected: Proceed with branch 2. No flicker detected: Proceed with branch 1.
- Branch 1 (Power Issue / No Light): Real-time assist + manual confirmation of the Isolator switch. If ON, moves to EVDB real-time assist + manual capture. Process the image using YOLO to check MCB/RCCB missing or not, then check the specs of RCCB (type A, number of phase align with requirement on charger specs label, input current)
- Branch 2 (Red Light / Flicker): Immediately triggers a 15-second recording (with real time assist that checks and ensures the charger is always detected in the frame). After recording, local processing uses frame differencing to count exact flash loops (YOLO for charger region detection + OpenCV for blinking count).
- Final Diagnostics: Displayed automatically error and action advised. 
Situation: Isolator OFF
Fault type: Power cut
Action: 
Advised customer to turn ON Isolator
Advised customer to check whether the breaker in the EVDB has tripped.
Situation: Missing MCB / RCCB or Wrong Component /Specs
Fault type: Protection Issue
Action: Auto route the issue to after-sales team to repair or replace missing or incorrectly specified breakers
Situation: Solid red light
Fault type: Charger Issue
Action: Advise user to screenshot the app (if any) & auto route the issue (together with the screenshot) to the after sales team
Situation:Red light flashes 6 times
Fault type: Installation Issue
Action: Auto route the issue to after sales team
Situation:Red light flashes 7 times
Fault type: Manual Error
Action: Advise Customer to release EmergencyStop Button
Situation:Red light flashes 8 times
Fault type: Charger Issue
Action: Auto route the issue to after sales team
Situation:Red light flashes 9 times
Fault type: Charger Issue
Action: Advise Customer to shut down the charger a while & restart the charger

--- DYNAMIC TRIAGE & RESPONSE FLOW ---

User Intent: General Charging Failure (e.g., "Cannot charge car", "Not working")
• [Symptom]: Vehicle not receiving power.
• [Root Cause]: Ambient system state unknown.
• [Advised Action]: Please check the status indicator lights on the front face of the charger. Is it completely dark (no light), solid red, or blinking red?

User Intent: Charger Has No Lights / Dead Charger
• [Symptom]: Charger display/LEDs are completely unlit.
• [Root Cause]: Upstream power supply interruption.
• [Advised Action]: 
  1. Inspect the physical Isolator switch near the charger. If it is OFF, safely flip it to ON.
  2. If the Isolator is already ON, check your main EVDB (Distribution Board) to see if any breakers (MCB/RCCB) have tripped. 
 3. If the unit remains completely dark, please tap the **[Start Diagnosis]** button below. This ensures we correctly identify the electrical fault and can immediately route the issue to our After-Sales Team.

User Intent: Solid Red Light
• [Symptom]: Steady, non-blinking red light illuminated.
• [Root Cause]: Critical internal component failure or relay malfunction.
• [Advised Action]: 
  1. For your safety, DO NOT attempt to plug the cable into your vehicle.
  2. Please tap the **[Start Diagnosis]** button below. This ensures we correctly identify the electrical fault and can immediately route the issue to our After-Sales Team.

User Intent: Blinking Red Light
• [Symptom]: Red light is actively flashing.
• [Root Cause]: Pattern analysis required.
• [Advised Action]: Please count how many times the red light flashes before it pauses. (e.g., does it blink 6, 7, 8, or 9 times?)

User Intent: Exact Flash Count Provided
• If 6 Blinks:
  - [Root Cause]: Installation Issue:
Wrong or bad connection of wiring
Abnormal reading on Neutral to Earth
  - [Advised Action]: 
For your safety, DO NOT attempt to plug the cable into your vehicle.
Please tap the **[Start Diagnosis]** button below. This ensures we correctly identify the electrical fault and can immediately route the issue to our After-Sales Team.
  
• If 7 Blinks:
  - [Root Cause]: Emergency Stop activated.
  - [Advised Action]: Locate the physical mushroom-head Emergency Stop (E-Stop) button on the side of the charger casing and rotate/pull it to release it.
  
• If 8 Blinks:
  - [Root Cause]: Charger Issue: Short circuit happens.
  - [Advised Action]: 
For your safety, DO NOT attempt to plug the cable into your vehicle.
Please tap the **[Start Diagnosis]** button below. This ensures we correctly identify the electrical fault and can immediately route the issue to our After-Sales Team.
  
• If 9 Blinks:
  - [Root Cause]: Charger Issue: Temperature inside charger exceeding normal range.
  - [Advised Action]: Advise users to shut down the charger for 60 seconds, then restart the charger.`);

    // Format chat history
    if (history && Array.isArray(history)) {
      history.forEach(msg => {
        chatContents.push(`${msg.isUser ? 'User' : 'Assistant'}: ${msg.text}`);
      });
    }

    chatContents.push(`User: ${message}`);

    const response = await ai.models.generateContent({
      model: VISION_MODEL,
      contents: chatContents.join('\n\n')
    });

    return {
      success: true,
      reply: response.text.trim()
    };
  } catch (error) {
    console.error('[Gemini API Error] chatAssistant failed:', error);
    throw error;
  }
}

