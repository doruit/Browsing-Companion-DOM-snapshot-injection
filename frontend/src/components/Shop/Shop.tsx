import React, { useRef, useEffect, useState } from 'react';
import { Navbar } from '../Navbar/Navbar';
import { ProductGrid } from '../ProductGrid/ProductGrid';
import { ChatWidget } from '../ChatWidget/ChatWidget';
import { DOMCaptureService } from '../../utils/domCapture';
import { Product, ProductFilters } from '../../types';

export const Shop: React.FC = () => {
  const domCaptureRef = useRef<DOMCaptureService | null>(null);
  const [chatbotFilters, setChatbotFilters] = useState<Partial<ProductFilters>>({});

  useEffect(() => {
    domCaptureRef.current = new DOMCaptureService();

    return () => {
      domCaptureRef.current?.disconnect();
    };
  }, []);

  const handleProductElementsChange = (elements: HTMLElement[], products: Product[]) => {
    if (domCaptureRef.current) {
      domCaptureRef.current.disconnect();
      domCaptureRef.current.observeProducts(elements, products);
    }
  };

  const handleCaptureSnapshot = () => {
    return domCaptureRef.current?.captureSnapshot() || null;
  };

  const handleFiltersFromChat = (filters: Partial<ProductFilters>) => {
    setChatbotFilters(filters);
  };

  return (
    <div>
      <Navbar />
      <ProductGrid 
        onProductElementsChange={handleProductElementsChange}
        externalFilters={chatbotFilters}
      />
      <ChatWidget 
        onCaptureSnapshot={handleCaptureSnapshot}
        onFiltersUpdate={handleFiltersFromChat}
      />
    </div>
  );
};
