import { useState, useCallback, useEffect } from 'react';
import { isDebug, useNuiEvent, fetchNui } from './hooks/useNui';

interface ItemData {
  name: string;
  label: string;
  amount: number;
}

interface OfferData {
  item: ItemData;
  offerPrice: number;
  reputation: number;
  tierName: string;
  priceModifier: number;
  minPrice: number;
  maxPrice: number;
  npcName: string;
  npcDialogue: {
    accept: string;
    reject: string;
  };
}

export default function App() {
  const [visible, setVisible] = useState(isDebug);
  const [offer, setOffer] = useState<OfferData | null>(null);
  const [negotiating, setNegotiating] = useState(false);
  const [negotiationResult, setNegotiationResult] = useState<{ success: boolean; repChange: number } | null>(null);
  const [isClosing, setIsClosing] = useState(false);

  // Mock data for development
  useEffect(() => {
    if (isDebug && !offer) {
      setOffer({
        item: { name: 'weed', label: 'Weed', amount: 5 },
        offerPrice: 45,
        reputation: 150,
        tierName: 'Hustler',
        priceModifier: 0.9,
        minPrice: 30,
        maxPrice: 80,
        npcName: 'Street Dealer',
        npcDialogue: {
          accept: "Pleasure doing business.",
          reject: "Aight, your loss homie."
        }
      });
    }
  }, [offer]);

  useNuiEvent('open', (data: OfferData) => {
    setOffer(data);
    setNegotiationResult(null);
    setNegotiating(false);
    setIsClosing(false);
    setVisible(true);
  });

  useNuiEvent('close', () => {
    setVisible(false);
    setOffer(null);
  });

  useNuiEvent('priceUpdate', (data: { newPrice: number; success: boolean; repChange: number; newRep: number; tierName: string }) => {
    if (offer) {
      setOffer({
        ...offer,
        offerPrice: data.newPrice,
        reputation: data.newRep,
        tierName: data.tierName
      });
    }
    setNegotiationResult({ success: data.success, repChange: data.repChange });
    setNegotiating(false);
  });

  const handleClose = useCallback(() => {
    if (isClosing) return;
    setIsClosing(true);
    fetchNui('close', {}, { success: true });
    setVisible(false);
    setOffer(null);
  }, [isClosing]);

  const handleAccept = useCallback(async () => {
    if (!offer || isClosing) return;
    setIsClosing(true);
    await fetchNui('acceptOffer', {}, { success: true });
  }, [offer, isClosing]);

  const handleReject = useCallback(async () => {
    if (isClosing) return;
    setIsClosing(true);
    await fetchNui('rejectOffer', {}, { success: true });
  }, [isClosing]);

  const handleNegotiate = useCallback(async () => {
    if (!offer || negotiating || isClosing) return;
    setNegotiating(true);
    setNegotiationResult(null);
    await fetchNui('negotiatePrice', {}, { success: true });
  }, [offer, negotiating, isClosing]);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleClose();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [handleClose]);

  if (!visible || !offer) return null;

  const totalPrice = offer.offerPrice * offer.item.amount;
  const tierColors: Record<string, string> = {
    'Rookie': 'text-gray-400',
    'Hustler': 'text-amber-400',
    'Dealer': 'text-emerald-400',
    'Kingpin': 'text-purple-400',
    'Legend': 'text-rose-400'
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black/50 backdrop-blur-sm">
      <div className="relative w-[420px] max-w-[95vw] animate-in fade-in zoom-in duration-200">
        {/* Main Card */}
        <div className="bg-gradient-to-b from-zinc-900 to-zinc-950 border border-zinc-700/50 rounded-xl shadow-2xl overflow-hidden">
          
          {/* Header - NPC Info */}
          <div className="relative bg-gradient-to-r from-amber-900/30 to-transparent px-5 py-4 border-b border-zinc-700/30">
            <div className="absolute top-0 left-0 w-1 h-full bg-gradient-to-b from-amber-500 to-amber-700" />
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-zinc-800 border border-zinc-600 flex items-center justify-center">
                <span className="text-lg">👤</span>
              </div>
              <div>
                <h2 className="text-white font-bold text-lg tracking-tight">{offer.npcName}</h2>
                <p className="text-zinc-400 text-xs">wants to make a deal</p>
              </div>
            </div>
          </div>

          {/* Item Section */}
          <div className="px-5 py-4 border-b border-zinc-700/30">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-zinc-500 text-xs uppercase tracking-wider mb-1">Item for Sale</p>
                <p className="text-white font-semibold text-xl">{offer.item.label}</p>
                <p className="text-zinc-400 text-sm">Qty: {offer.item.amount}</p>
              </div>
              <div className="text-right">
                <p className="text-zinc-500 text-xs uppercase tracking-wider mb-1">Offer Price</p>
                <div className="flex items-baseline gap-1">
                  <span className="text-emerald-400 font-bold text-2xl">${offer.offerPrice}</span>
                  <span className="text-zinc-500 text-sm">/ea</span>
                </div>
              </div>
            </div>
          </div>

          {/* Total Price */}
          <div className="px-5 py-3 bg-zinc-800/40 border-b border-zinc-700/30">
            <div className="flex items-center justify-between">
              <span className="text-zinc-400 text-sm">Total Price</span>
              <span className="text-emerald-400 font-bold text-xl">${totalPrice}</span>
            </div>
          </div>

          {/* Negotiation Result */}
          {negotiationResult && (
            <div className={`px-5 py-2 text-center text-sm font-medium ${
              negotiationResult.success 
                ? 'bg-emerald-900/30 text-emerald-400' 
                : 'bg-red-900/30 text-red-400'
            }`}>
              {negotiationResult.success ? (
                <span>Negotiation successful! (+{negotiationResult.repChange} rep)</span>
              ) : (
                <span>They weren't having it... ({negotiationResult.repChange} rep)</span>
              )}
            </div>
          )}

          {/* Action Buttons */}
          <div className="px-5 py-4 space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={handleAccept}
                disabled={isClosing}
                className="relative py-3 px-4 bg-gradient-to-r from-emerald-600 to-emerald-700 hover:from-emerald-500 hover:to-emerald-600 text-white font-semibold rounded-lg transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-emerald-900/20"
              >
                Accept
              </button>
              <button
                onClick={handleReject}
                disabled={isClosing}
                className="py-3 px-4 bg-zinc-700 hover:bg-zinc-600 text-zinc-200 font-semibold rounded-lg transition-colors duration-150 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Reject
              </button>
            </div>

            {/* Negotiate Button */}
            <button
              onClick={handleNegotiate}
              disabled={negotiating || isClosing}
              className="w-full py-3 px-4 bg-gradient-to-r from-amber-600/20 to-amber-500/20 hover:from-amber-600/30 hover:to-amber-500/30 border border-amber-600/40 hover:border-amber-500/60 text-amber-400 font-semibold rounded-lg transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {negotiating ? (
                <>
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  <span>Negotiating...</span>
                </>
              ) : (
                <>
                  <span>🎲</span>
                  <span>Try to Negotiate</span>
                </>
              )}
            </button>
            <p className="text-center text-zinc-500 text-xs">Risk reputation for a better price</p>
          </div>

          {/* Reputation Footer */}
          <div className="px-5 py-3 bg-zinc-800/60 border-t border-zinc-700/30">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-zinc-500 text-sm">Reputation:</span>
                <span className={`font-semibold ${tierColors[offer.tierName] || 'text-white'}`}>
                  {offer.tierName}
                </span>
              </div>
              <div className="flex items-center gap-1 text-zinc-400 text-sm">
                <span>{offer.reputation} rep</span>
                <span className="text-zinc-600">|</span>
                <span>{Math.round(offer.priceModifier * 100)}% prices</span>
              </div>
            </div>
          </div>
        </div>

        {/* Close hint */}
        <p className="text-center text-zinc-600 text-xs mt-3">Press ESC to close</p>
      </div>
    </div>
  );
}
