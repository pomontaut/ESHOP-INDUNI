class OrderMailer < ApplicationMailer
  default from: 'commandes@induni.ch'

  def send_order(order, pdf)
    @order = order
    attachments["commande_#{@order.number}.pdf"] = {
      mime_type: 'application/pdf',
      content: pdf
    }
    mail(
      to: @order.supplier.email,
      subject: "Commande #{@order.number} - ESHOP INDUNI"
    )
  end
end
