class Admin::SuppliersController < ApplicationController
  before_action :require_admin
  before_action :set_supplier, only: [ :edit, :update ]

  def index
    @suppliers = Supplier.order(:name)
  end

  def edit
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to admin_suppliers_path, notice: "Paramétrage de #{@supplier.name} mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Accès réservé aux administrateurs."
    end
  end

  def supplier_params
    all_cantons = params[:supplier][:all_cantons] == "1"
    all_sectors = params[:supplier][:all_sectors] == "1"

    permitted = params.require(:supplier).permit(
      :email, :email_geneve, :email_vaud, :email_valais, :email_fribourg, :email_jura,
      visible_cantons: [], visible_sectors: []
    )
    permitted[:visible_cantons] = all_cantons ? [] : (permitted[:visible_cantons] || []).reject(&:blank?)
    permitted[:visible_sectors] = all_sectors ? [] : (permitted[:visible_sectors] || []).reject(&:blank?)
    permitted
  end
end
