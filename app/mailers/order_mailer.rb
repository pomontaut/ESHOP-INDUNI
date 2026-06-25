class OrderMailer < ApplicationMailer
  def send_order(order)
    @order = order
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: 'orders/show',
        formats: [:html],
        layout: 'pdf'
      )
    )
    attachments["commande_#{@order.number}.pdf"] = { mime_type: 'application/pdf', content: pdf }
    mail(
      to: @order.supplier.email,
      subject: "Commande #{@order.number}"
    )
  end
end
