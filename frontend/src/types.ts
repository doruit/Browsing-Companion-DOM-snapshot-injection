export interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  description: string;
  discount: number;
  b2b_available: boolean;
  b2c_available: boolean;
  image: string;
  in_stock: boolean;
}

export interface User {
  id: string;
  email: string;
  name: string;
}

export interface Preferences {
  userId: string;
  is_b2b: boolean;
  preferred_categories: string[];
  hidden_categories: string[];
}

export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

export interface DOMSnapshot {
  visible_products: Array<{
    id: string;
    name: string;
    category: string;
    price: number;
    discount?: number;
    description?: string;
    visible: boolean;
  }>;
  page_url: string;
  timestamp: number;
}
