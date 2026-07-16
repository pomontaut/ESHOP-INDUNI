export const SUIVI_STATUS_OPTS: [string, string][] = [
  ["A_envoyer", "À envoyer"],
  ["Envoye", "Envoyé"],
  ["Relance1", "Relancé (1)"],
  ["Relance2", "Relancé (2)"],
  ["OffreRecue", "Offre reçue"],
  ["Retenu", "Retenu"],
  ["Decline", "Décliné"],
];

export const SUIVI_STATUS_VALUES = SUIVI_STATUS_OPTS.map(([v]) => v);

export const LOT_STATUS_VALUES = ["proposed", "validated"] as const;

export const LOT_SUPPLIER_STATUS_VALUES = ["suggested", "validated", "dismissed"] as const;
