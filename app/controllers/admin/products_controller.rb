class Admin::ProductsController < ApplicationController
  before_action :require_admin

  XLSX_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

  def index
    @suppliers = Supplier.order(:name)
    @product_count = Product.count
    @change_count = ProductPriceChange.count
  end

  # Extraction Excel des prix de tous les produits (ou d'un fournisseur) avec
  # l'historique des modifications de prix : date + nouveau prix, une ligne par
  # modification réelle. Les prix des fournisseurs à prix confidentiel (ex.
  # Sika) ne sortent jamais d'ici — voir Supplier#confidential_pricing.
  def export
    products = Product.includes(:supplier).order("suppliers.name", :reference).references(:supplier)
    products = products.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?
    changes = ProductPriceChange.where(product_id: products.map(&:id)).order(:product_id, :changed_at, :id).group_by(&:product_id)

    package = Axlsx::Package.new
    package.workbook.use_shared_strings = true
    build_workbook(package.workbook, products, changes)

    stamp = Time.current.strftime("%Y-%m-%d")
    send_data package.to_stream.read, filename: "prix-produits-#{stamp}.xlsx", type: XLSX_TYPE, disposition: "attachment"
  end

  private

  def build_workbook(wb, products, changes)
    header = wb.styles.add_style(b: true, bg_color: "0C1D34", fg_color: "FFFFFF", alignment: { vertical: :center })
    money  = wb.styles.add_style(format_code: "#,##0.00")
    date   = wb.styles.add_style(format_code: "dd.mm.yyyy hh:mm")

    wb.add_worksheet(name: "Prix actuels") do |sheet|
      sheet.add_row [ "Fournisseur", "Référence", "Désignation", "Famille", "Sous-famille", "Unité",
                      "Prix actuel (CHF)", "Prix externe (CHF)", "Dernière modification de prix", "Nb de modifications" ], style: header
      products.each do |p|
        confidential = p.supplier&.confidential_pricing?
        list = changes[p.id] || []
        # Le premier relevé est le prix initial, pas une « modification ».
        modifications = [ list.size - 1, 0 ].max
        sheet.add_row [ p.supplier&.name, p.reference, p.name, p.famille, p.sous_famille, p.unite,
                        confidential ? "Confidentiel" : p.unit_price&.to_f,
                        confidential ? nil : p.prix_externe&.to_f,
                        confidential ? nil : list.last&.changed_at,
                        confidential ? nil : modifications ],
                      style: [ nil, nil, nil, nil, nil, nil, money, money, date, nil ]
      end
      sheet.auto_filter = "A1:J#{products.size + 1}"
      sheet.sheet_view.pane { |pane| pane.state = :frozen; pane.y_split = 1; pane.top_left_cell = "A2" }
      sheet.column_widths 18, 16, 60, 24, 24, 8, 16, 16, 24, 12
    end

    wb.add_worksheet(name: "Historique des prix") do |sheet|
      sheet.add_row [ "Fournisseur", "Référence", "Désignation", "Date", "Nouveau prix (CHF)", "Type" ], style: header
      rows = 0
      products.each do |p|
        next if p.supplier&.confidential_pricing?

        (changes[p.id] || []).each_with_index do |c, i|
          sheet.add_row [ p.supplier&.name, p.reference, p.name, c.changed_at, c.price.to_f, i.zero? ? "Prix initial" : "Modification" ],
                        style: [ nil, nil, nil, date, money, nil ]
          rows += 1
        end
      end
      sheet.auto_filter = "A1:F#{rows + 1}"
      sheet.sheet_view.pane { |pane| pane.state = :frozen; pane.y_split = 1; pane.top_left_cell = "A2" }
      sheet.column_widths 18, 16, 60, 20, 18, 14
    end
  end

  def require_admin
    redirect_to root_path, alert: "Accès réservé aux administrateurs." unless current_user&.admin?
  end
end
