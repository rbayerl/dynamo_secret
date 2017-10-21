module DynamoSecret
  class Gpg
    def decrypt(data)
      crypto.decrypt(data).read
    rescue GPGME::Error::NoData
      $stderr.puts 'Key was found but GPG decrypt failed - skipping'
      data
    end

    def encrypt(data)
      crypto.encrypt(data, recipients: [key.uids.first.name]).read
    end

    def key
      @gpg_key ||= GPGME::Key.find(:secret).map { |k| k if k.expires > Date.today.to_time }.first
    end

    private

    def crypto
      @crypto ||= GPGME::Crypto.new
    end
  end
end
