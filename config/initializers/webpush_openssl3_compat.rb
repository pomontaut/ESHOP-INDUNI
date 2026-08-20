# The webpush gem (1.1.0, latest as of writing) builds elliptic-curve keys
# by mutating an already-constructed OpenSSL::PKey::EC in place
# (`OpenSSL::PKey::EC.new(curve).generate_key`, or assigning
# `curve.public_key =` / `curve.private_key =` after construction). OpenSSL
# 3.0 forbids mutating a key after it's built ("pkeys are immutable"), which
# breaks both Webpush::VapidKey (loading our stored VAPID key pair) and
# Webpush::Encryption (the ephemeral per-message key). Patches both to build
# the key once, either via the modern `OpenSSL::PKey::EC.generate` (fresh
# key) or by encoding a raw private scalar + public point into a one-shot
# SEC1 ECPrivateKey DER structure (loading existing key material) — same
# output, just never mutated after construction. Delete this file if a
# future webpush release fixes it upstream.
require "webpush"

module Webpush
  module Encryption
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = "prime256v1"
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)
      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)
      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = "#{salt}" + [ rs ].pack("N*") + [ serverkey16bn.bytesize ].pack("C*") + serverkey16bn
      aes128gcmheader + ciphertext
    end
  end

  class VapidKey
    def initialize
      @curve = OpenSSL::PKey::EC.generate("prime256v1")
    end

    def public_key=(key)
      @pending_public_key_bn = to_big_num(key)
      rebuild_curve!
    end

    def private_key=(key)
      @pending_private_key_bn = to_big_num(key)
      rebuild_curve!
    end

    private

    def rebuild_curve!
      return unless @pending_private_key_bn

      priv_bytes = @pending_private_key_bn.to_s(2).rjust(32, "\x00")
      pub_bytes =
        if @pending_public_key_bn
          @pending_public_key_bn.to_s(2)
        else
          group.generator.mul(@pending_private_key_bn).to_bn.to_s(2)
        end

      asn1 = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer(1),
        OpenSSL::ASN1::OctetString(priv_bytes),
        OpenSSL::ASN1::ASN1Data.new([ OpenSSL::ASN1::ObjectId("prime256v1") ], 0, :CONTEXT_SPECIFIC),
        OpenSSL::ASN1::ASN1Data.new([ OpenSSL::ASN1::BitString(pub_bytes) ], 1, :CONTEXT_SPECIFIC)
      ])
      @curve = OpenSSL::PKey::EC.new(asn1.to_der)
    end
  end
end
