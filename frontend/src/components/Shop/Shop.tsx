import React, { useRef, useEffect } from 'react';
import { Navbar } from '../Navbar/Navbar';
import { ProductGrid } from '../ProductGrid/ProductGrid';
import { ChatWidget } from '../ChatWidget/ChatWidget';
import { DOMCaptureService } from '../../utils/domCapture';
import { Product } from '../../types';

export const Shop: React.FC = () => {
  const domCaptureRef = useRef<DOMCaptureService | null>(null);

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

  return (
    <div>
      <Navbar />
      <ProductGrid onProductElementsChange={handleProductElementsChange} />
      <ChatWidget onCaptureSnapshot={handleCaptureSnapshot} />
    </div>
  );
};
