double calculerSoldeNetLivreur({
  required double creditEnLigne,
  required double montantAReverser,
  required double paiementsLivreurAcceptes,
  required double versementsEntrepriseAcceptes,
}) {
  return creditEnLigne -
      montantAReverser -
      versementsEntrepriseAcceptes +
      paiementsLivreurAcceptes;
}
