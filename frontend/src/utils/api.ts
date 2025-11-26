const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001';

export class ApiClient {
  private token: string | null = null;

  constructor() {
    this.token = localStorage.getItem('auth_token');
  }

  setToken(token: string) {
    this.token = token;
    localStorage.setItem('auth_token', token);
  }

  clearToken() {
    this.token = null;
    localStorage.removeItem('auth_token');
  }

  private async request(endpoint: string, options: RequestInit = {}) {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    if (options.headers) {
      Object.assign(headers, options.headers);
    }

    const response = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Request failed' }));
      throw new Error(error.error || `HTTP ${response.status}`);
    }

    return response.json();
  }

  async login(email: string, password: string) {
    const data = await this.request('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    this.setToken(data.token);
    return data;
  }

  async getProducts(filters?: {
    category?: string;
    customer_type?: string;
    search?: string;
  }) {
    const params = new URLSearchParams();
    if (filters?.category) params.append('category', filters.category);
    if (filters?.customer_type) params.append('customer_type', filters.customer_type);
    if (filters?.search) params.append('search', filters.search);
    
    const query = params.toString();
    return this.request(`/api/products${query ? `?${query}` : ''}`);
  }

  async sendChatMessage(message: string, domSnapshot?: any, sessionId?: string) {
    return this.request('/api/chat', {
      method: 'POST',
      body: JSON.stringify({
        message,
        dom_snapshot: domSnapshot,
        session_id: sessionId,
      }),
    });
  }

  async getPreferences() {
    return this.request('/api/preferences');
  }

  async updatePreferences(preferences: any) {
    return this.request('/api/preferences', {
      method: 'POST',
      body: JSON.stringify(preferences),
    });
  }
}

export const apiClient = new ApiClient();
