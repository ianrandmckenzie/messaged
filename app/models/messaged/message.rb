module Messaged
  class Message < ApplicationRecord
    include ActionView::RecordIdentifier

    # User association
    belongs_to :user,
      class_name: Messaged.user_class_name,
      inverse_of: :messaged_messages,
      optional: true
    # Multi-tenant option
    if Messaged.tenant_class_name
      belongs_to :tenant,
        class_name: Messaged.tenant_class_name,
        inverse_of: :messaged_messages,
        optional: true
    end
    belongs_to :room, optional: true

    has_rich_text :content
    validates :content, presence: true

    after_create_commit -> { broadcast_append_later_to [owner, "messages"], target: "messages", partial: "messages/message" }
    after_update_commit -> { broadcast_replace_later_to [owner, "messages"], target: "#{dom_id(self)}", partial: "messages/message" }
    after_destroy_commit -> { broadcast_remove_to [owner, "messages"] }
  end

  # Messages should default to the person sending them, otherwise
  # fallback to the chat room, and finally tenant if they exist.
  def owner
    return user if user
    return room if room
    return tenant if Messaged.tenant_class_name && tenant
    return nil # replace with user, tenant, or room
  end
end