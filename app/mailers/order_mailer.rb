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
end
