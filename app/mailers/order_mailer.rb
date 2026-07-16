class OrderMailer < ApplicationMailer
  def send_order(order, pdf_content = nil)
    @order = order
    if pdf_content
      attachments["commande_#{@order.number}.pdf"] = { mime_type: 'application/pdf', content: pdf_content }
    end
    mail(to: @order.supplier.email, subject: "Commande #{@order.number}")
  end

  def send_order_plain(order)
    @order = order
    mail(to: @order.supplier.email, subject: "Commande #{@order.number}")
  end

  def approval_request(order)
    @order       = order
    @user        = order.user
    @approve_url = Rails.application.routes.url_helpers.approve_approval_url(@order.approval_token, host: default_url_options[:host])
    @refuse_url  = Rails.application.routes.url_helpers.refuse_approval_url(@order.approval_token, host: default_url_options[:host])
    @review_url  = Rails.application.routes.url_helpers.approval_url(@order.approval_token, host: default_url_options[:host])
    mail(
      to:      order.approver_email,
      subject: "Approbation requise — Commande #{order.number} (#{number_with_delimiter(order.total.to_i)} CHF)"
    )
  end

  def approval_approved(order)
    @order = order
    @user  = order.user
    return unless @user&.email
    mail(to: @user.email, subject: "✅ Commande #{order.number} approuvée — vous pouvez l'envoyer au fournisseur")
  end

  def approval_refused(order)
    @order = order
    @user  = order.user
    return unless @user&.email
    mail(to: @user.email, subject: "❌ Commande #{order.number} refusée — #{order.approval_comment&.truncate(60)}")
  end
end
