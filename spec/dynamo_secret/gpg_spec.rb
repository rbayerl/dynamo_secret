require 'spec_helper'
require 'dynamo_secret/gpg'

SingleCov.covered!

describe DynamoSecret::Gpg do
  it 'decrypts data with gpg' do
    expect_any_instance_of(GPGME::Crypto).to receive(:decrypt).with('foo').and_return(OpenStruct.new(read: 'bar'))
    expect(described_class.new.decrypt('foo')).to eq('bar')
  end

  it 'skips decrypting if not encrypted' do
    expect_any_instance_of(GPGME::Crypto).to receive(:decrypt).with('foo').and_raise(GPGME::Error::NoData.new(1))
    expect_any_instance_of(IO).to receive(:puts).with('Key was found but GPG decrypt failed - skipping')
    expect(described_class.new.decrypt('foo')).to eq('foo')
  end

  it 'encrypts data' do
    expect(GPGME::Key).to receive(:find).with(:secret).and_return(
      [
        OpenStruct.new(
          uids: [
            OpenStruct.new(
              name: 'foobar-user'
            )
          ],
          expires: Date.today.next_day.to_time
        )
      ]
    )
    expect_any_instance_of(GPGME::Crypto).to receive(:encrypt).with(
      'foobar',
      recipients: ['foobar-user']
    ).and_return(OpenStruct.new(read: 'bar'))
    expect(described_class.new.encrypt('foobar')).to eq('bar')
  end
end
