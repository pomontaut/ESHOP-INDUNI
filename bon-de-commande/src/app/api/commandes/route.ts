import { NextRequest, NextResponse } from "next/server";
import { getAllCommandes, saveCommande, getNextNumero, BonDeCommande } from "../../lib/db";
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2);
}

export async function GET() {
  const commandes = getAllCommandes();
  return NextResponse.json(commandes);
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const numero = getNextNumero();
  const commande: BonDeCommande = {
    ...body,
    id: generateId(),
    numero,
    createdAt: new Date().toISOString(),
  };
  saveCommande(commande);
  return NextResponse.json(commande, { status: 201 });
}