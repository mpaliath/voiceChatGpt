/**
 * Replace common PII patterns with tagged tokens.
 * Emails -> [REDACTED:EMAIL]
 * Phone numbers -> [REDACTED:PHONE]
 * Credit cards -> [REDACTED:CARD]
 * Addresses (simple street addr) -> [REDACTED:ADDRESS]
 */
function redactPII(text = '') {
  if (!text) return '';
  return text
    // emails
    .replace(/([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[A-Za-z]{2,})/g, '[REDACTED:EMAIL]')
    // phone numbers (123-456-7890 or (123) 456 7890)
    .replace(/(\+?\d{1,2}[\s-]?)?(\(?\d{3}\)?[\s-]?\d{3}[\s-]?\d{4})/g, '[REDACTED:PHONE]')
    // credit cards (16 digits)
    .replace(/\b(?:\d[ -]*?){13,16}\b/g, '[REDACTED:CARD]')
    // simple street addresses
    .replace(/\b\d+\s+(?:[A-Za-z0-9]+\s+){0,3}(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln)\b/gi, '[REDACTED:ADDRESS]');
}

module.exports = { redactPII };
