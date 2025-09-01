const { redactPII } = require('../redactor');

describe('redactPII', () => {
  test('redacts email', () => {
    const input = 'Contact me at test@example.com';
    expect(redactPII(input)).toBe('Contact me at [REDACTED:EMAIL]');
  });
  test('redacts phone', () => {
    const input = 'Call 123-456-7890 later';
    expect(redactPII(input)).toBe('Call [REDACTED:PHONE] later');
  });
  test('redacts card', () => {
    const input = 'Card 4111 1111 1111 1111';
    expect(redactPII(input)).toBe('Card [REDACTED:CARD]');
  });
  test('redacts address', () => {
    const input = 'Meet at 123 Main Street tomorrow';
    expect(redactPII(input)).toBe('Meet at [REDACTED:ADDRESS] tomorrow');
  });
});
