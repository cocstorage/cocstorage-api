class Storage < ApplicationRecord
  belongs_to :storage_category
  belongs_to :user

  has_one_attached :avatar

  validate :path_inspection, on: %i[create update]
  validate :name_inspection, on: %i[create update]
  validate :description_inspection, on: %i[create update]
  validate :avatar_inspection, on: %i[create update]

  private

  def path_inspection
    if path.present?
      normal_regex = /[a-zA-Z0-9]{3,20}/
      special_regex = "[ !@\#$%^&*(),.?\":{}|<>]"

      raise Errors::BadRequest.new(code: 'COC001', message: 'storage path is invalid') unless path =~ normal_regex
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage path is invalid') if path.length > 20
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage path is invalid') if path.match(special_regex)

      storage = Storage.find_by(path: path)
      if storage.present? && id != storage.id
        raise Errors::BadRequest.new(code: 'COC024', message: 'storage path already exists')
      end
    end
  end

  def name_inspection
    if name.present?
      regex = /[ㄱ-ㅎㅏ-ㅣ가-힣a-zA-Z0-9\-]{3,20}/
      special_regex = "[!@\#$%^&*(),.?\":{}|<>]"

      raise Errors::BadRequest.new(code: 'COC001', message: 'storage name is invalid') unless name =~ regex
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage name is invalid') if name.length > 20
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage name is invalid') if name.match(special_regex)

      storage = Storage.find_by(name: name)
      if storage.present? && id != storage.id
        raise Errors::BadRequest.new(code: 'COC025', message: 'storage name already exists')
      end
    end
  end

  def description_inspection
    if description.present?
      raise Errors::BadRequest.new(code: 'COC002', message: 'description is invalid') if description.length > 200
    end
  end

  def avatar_inspection
    if avatar.attached? && !avatar.content_type.in?(%w[image/png image/gif image/jpg image/jpeg])
      Errors::BadRequest.new(code: 'COC016', message: "#{avatar.content_type} is unacceptable image format")
    end
  end
end
