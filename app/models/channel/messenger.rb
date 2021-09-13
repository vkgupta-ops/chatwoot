# == Schema Information
#
# Table name: channel_facebook_pages
#
#  id                :integer          not null, primary key
#  page_access_token :string           not null
#  user_access_token :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :integer          not null
#  page_id           :string           not null
#
# Indexes
#
#  index_channel_facebook_pages_on_page_id                 (page_id)
#  index_channel_facebook_pages_on_page_id_and_account_id  (page_id,account_id) UNIQUE
#

class Channel::Messenger < ApplicationRecord
  self.table_name = 'channel_messenger'

  include Reauthorizable

  validates :account_id, presence: true
  validates :page_id, uniqueness: { scope: :account_id }
  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  after_create_commit :subscribe
  before_destroy :unsubscribe

  def name
    'Messenger'
  end

  def has_24_hour_messaging_window?
    true
  end

  def subscribe
    # ref https://developers.facebook.com/docs/messenger-platform/reference/webhook-events
    response = Facebook::Messenger::Subscriptions.subscribe(
      access_token: page_access_token,
      subscribed_fields: %w[
        messages messaging_postbacks messaging_handover
      ]
    )
  rescue => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  def unsubscribe
    Facebook::Messenger::Subscriptions.unsubscribe(access_token: page_access_token)
  rescue => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end
end
