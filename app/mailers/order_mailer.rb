class OrderMailer < ApplicationMailer
  DEFAULT_BODY = "Bonjour,\n\nVeuillez trouver ci-joint le bon de commande.\n\nMerci de bien vouloir nous faire parvenir votre confirmation de commande dans les plus brefs délais.\n\nRestant à votre disposition pour toute information complémentaire.\n\nCordialement\nINDUNI & Cie SA\nAvenue des Grandes-Communes 6\n1213 Petit-Lancy"

  def send_order(order, pdf_content = nil, to: nil, cc: nil, subject: nil, body: nil)
    @order = order
    @body  = body.presence || DEFAULT_BODY
    if pdf_content
      attachments["commande_#{@order.number}.pdf"] = { mime_type: "application/pdf", content: pdf_content }
    end
    mail(to: to.presence || @order.supplier.email, cc: cc.presence, subject: subject.presence || "Commande #{@order.number}")
  end

  def send_order_plain(order)
    @order = order
    mail(to: @order.supplier.email, subject: "Commande #{@order.number}")
  end

  # Notifies every admin when a user re-submits a previously generated order
  # with changes (via "Modifier" in the dashboard), so they know who changed
  # what, and when, without having to compare two orders by hand.
  def order_modified(new_order, original_order, diff, editor)
    @new_order      = new_order
    @original_order = original_order
    @diff           = diff
    @editor         = editor
    admin_emails = User.where(admin: true).pluck(:email)
    return if admin_emails.empty?
    mail(to: admin_emails, subject: "Commande #{original_order.number} modifiée par #{editor&.full_name || 'un utilisateur'} — nouvelle commande #{new_order.number}")
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
