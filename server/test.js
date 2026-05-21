import { chatAssistant } from './services/gemini.js';

async function main() {
  try {
    const result = await chatAssistant([], "Cannot charge car");
    console.log("RESULT:", result);
  } catch (err) {
    console.error("ERROR:", err);
  }
}

main();
