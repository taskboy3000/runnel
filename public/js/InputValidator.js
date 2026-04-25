export function validateSearchTerm(term) {
    if (typeof term !== 'string') return null;
    const trimmed = term.trim();
    if (trimmed.length === 0) return null;
    if (trimmed.length > 255) return null;
    return trimmed;
}