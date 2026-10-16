require "net/http"

# Disponibilité d'un article HGC telle qu'affichée sur hgc.ch (pastille verte
# « livrable immédiatement | NPA 1213 »). Le site n'expose pas d'API publique :
# la fiche produit embarque le statut de stock (`stockLevelStatus`) calculé pour
# le NPA du cookie anonyme `hgc.anonymousZipCode`. Aucun compte HGC requis.
# Mis en cache quelques minutes pour ne pas solliciter leur site à chaque clic.
class HgcStock
  DEFAULT_ZIP = ENV.fetch("HGC_STOCK_ZIP", "1213")
  CACHE_TTL = 15.minutes
  # Code HGC → [libellé, niveau] ; niveau = ok (vert) / ask (orange) / no (rouge).
  STATUSES = {
    "deliverable"               => [ "Livrable immédiatement", "ok" ],
    "pickable"                  => [ "Disponible au dépôt", "ok" ],
    "pickableInOtherStore"      => [ "Disponible dans un autre dépôt", "ask" ],
    "orderOnDemandDeliverable"  => [ "Livrable sur commande", "ask" ],
    "soonDeliverable"           => [ "Bientôt livrable (date à confirmer)", "ask" ],
    "securityRestricted"        => [ "Livraison restreinte (voir fiche HGC)", "ask" ],
    "outOfStock"                => [ "Rupture de stock", "no" ],
    "notDeliverable"            => [ "Non livrable", "no" ],
    "temporaryNotDeliverable"   => [ "Temporairement non livrable", "no" ],
    "notOrderable"              => [ "Non commandable", "no" ],
    "temporaryNotOrderable"     => [ "Temporairement non commandable", "no" ]
  }.freeze
  ARTICLE_FORMAT = /\A\d{6,12}\z/
  ZIP_FORMAT = /\A\d{4}\z/

  # => { article:, zip:, code:, label:, level:, url: } ou nil si illisible.
  def self.lookup(article, zip = DEFAULT_ZIP)
    article = article.to_s
    zip = zip.to_s.presence || DEFAULT_ZIP
    return nil unless article.match?(ARTICLE_FORMAT) && zip.match?(ZIP_FORMAT)

    Rails.cache.fetch([ "hgc_stock", article, zip ], expires_in: CACHE_TTL, skip_nil: true) do
      html, url = fetch_page(article, zip)
      code = html && parse_status(html)
      next nil unless code
      label, level = STATUSES.fetch(code, [ code, "ask" ])
      { article: article, zip: zip, code: code, label: label, level: level, url: url }
    end
  rescue StandardError => e
    Rails.logger.warn("HgcStock #{article}/#{zip}: #{e.class} #{e.message}")
    nil
  end

  # Le premier `stockLevelStatus` de la page est celui de l'article lui-même
  # (les suivants concernent des produits associés).
  def self.parse_status(html)
    html[/"stockLevelStatus":\{"code":"([A-Za-z]+)"/, 1]
  end

  def self.fetch_page(article, zip)
    uri = URI("https://www.hgc.ch/fr/search?text=#{article}")
    4.times do
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      req = Net::HTTP::Get.new(uri)
      req["Cookie"] = "hgc.anonymousZipCode=#{zip}"
      req["User-Agent"] = "Induni-Achats/1.0 (+stock)"
      res = http.request(req)
      case res
      when Net::HTTPSuccess then return [ res.body.to_s.force_encoding("UTF-8"), uri.to_s ]
      when Net::HTTPRedirection then uri = URI.join(uri.to_s, res["location"])
      else return nil
      end
    end
    nil
  end
end
