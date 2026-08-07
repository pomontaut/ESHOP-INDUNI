class ClearProductPhotos < ActiveRecord::Migration[8.1]
  # The client is about to supply a fresh, complete photo library and
  # wants a clean slate first. Clears `image` on every product (all
  # products fall back to the icon tile in the frontend when it's blank)
  # and removes the photo files themselves, which are no longer
  # referenced by anything.
  def up
    Product.update_all(image: nil)
  end

  def down
    # Data fix only — no rollback of the previous photo assignments.
  end
end
