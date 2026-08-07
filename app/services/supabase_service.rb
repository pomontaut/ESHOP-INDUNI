require "net/http"
require "json"

class SupabaseService
  URL  = ENV.fetch("SUPABASE_URL", "https://udlwkwryehrnjaqisvab.supabase.co")
  KEY  = ENV.fetch("SUPABASE_SERVICE_KEY", "")

  HEADERS = {
    "apikey"        => KEY,
    "Authorization" => "Bearer #{KEY}",
    "Content-Type"  => "application/json",
    "Prefer"        => "return=representation"
  }.freeze

  # Retourne tous les fournisseurs depuis Supabase
  def self.fetch_suppliers
    get("/rest/v1/suppliers?select=*&order=name.asc")
  end

  # Retourne un fournisseur par nom (insensible à la casse)
  def self.find_supplier_by_name(name)
    encoded = URI.encode_uri_component(name)
    result = get("/rest/v1/suppliers?name=ilike.#{encoded}&select=*&limit=1")
    result&.first
  end

  # Crée un fournisseur dans Supabase
  def self.create_supplier(attrs)
    post("/rest/v1/suppliers", attrs)
  end

  # Met à jour un fournisseur dans Supabase
  def self.update_supplier(id, attrs)
    patch("/rest/v1/suppliers?id=eq.#{id}", attrs)
  end

  # Supprime un fournisseur dans Supabase
  def self.delete_supplier(id)
    delete("/rest/v1/suppliers?id=eq.#{id}")
  end

  # Synchronise les fournisseurs Supabase → SQLite local
  def self.sync_to_local!
    remote = fetch_suppliers
    return { synced: 0, errors: [ "Impossible de contacter Supabase" ] } if remote.nil?

    synced = 0
    remote.each do |s|
      supplier = Supplier.find_or_initialize_by(name: s["name"])
      supplier.assign_attributes(
        email:   s["email"].presence || supplier.email,
        phone:   s["phone"].presence || supplier.phone,
        address: s["address"].presence || supplier.address
      )
      supplier.save! if supplier.changed?
      synced += 1
    end
    { synced: synced, errors: [] }
  rescue => e
    { synced: 0, errors: [ e.message ] }
  end

  private

  def self.get(path)
    request(:get, path)
  end

  def self.post(path, body)
    request(:post, path, body)
  end

  def self.patch(path, body)
    request(:patch, path, body)
  end

  def self.delete(path)
    request(:delete, path)
  end

  def self.request(method, path, body = nil)
    uri = URI("#{URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req_class = { get: Net::HTTP::Get, post: Net::HTTP::Post,
                  patch: Net::HTTP::Patch, delete: Net::HTTP::Delete }[method]
    req = req_class.new(uri.request_uri)
    HEADERS.each { |k, v| req[k] = v }
    req.body = body.to_json if body

    response = http.request(req)
    return nil if response.code.to_i >= 400

    JSON.parse(response.body) rescue nil
  end
end
