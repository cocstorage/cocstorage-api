#https://github.com/rails/rails/issues/31419#issuecomment-370900013
#https://gist.github.com/dinatih/dbfdfd4e84faac4037448a06c9fdc016 : rails6 version (원래는 private이 default인데, public을 default로 변경했음)
Rails.application.config.to_prepare do
  # Provides the class-level DSL for declaring that an Active Record model has attached blobs.
  ActiveStorage::Attached::Model.module_eval do
    class_methods do
      def has_one_attached(name, dependent: :purge_later, acl: :public)
        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}
            @active_storage_attached_#{name} ||= ActiveStorage::Attached::One.new("#{name}", self, acl: "#{acl}")
          end
          def #{name}=(attachable)
            attachment_changes["#{name}"] =
              if attachable.nil?
                ActiveStorage::Attached::Changes::DeleteOne.new("#{name}", self)
              else
                ActiveStorage::Attached::Changes::CreateOne.new("#{name}", self, attachable, acl: "#{acl}")
              end
          end
        CODE

        has_one :"#{name}_attachment", -> { where(name: name) }, class_name: "ActiveStorage::Attachment", as: :record, inverse_of: :record, dependent: :destroy
        has_one :"#{name}_blob", through: :"#{name}_attachment", class_name: "ActiveStorage::Blob", source: :blob

        scope :"with_attached_#{name}", -> { includes("#{name}_attachment": :blob) }

        after_save { attachment_changes[name.to_s]&.save }

        after_commit(on: %i[ create update ]) { attachment_changes.delete(name.to_s).try(:upload) }

        ActiveRecord::Reflection.add_attachment_reflection(
          self,
          name,
          ActiveRecord::Reflection.create(:has_one_attached, name, nil, { dependent: dependent }, self)
        )
      end

      def has_many_attached(name, dependent: :purge_later, acl: :public)
        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}
            @active_storage_attached_#{name} ||= ActiveStorage::Attached::Many.new("#{name}", self, acl: "#{acl}")
          end
          def #{name}=(attachables)
            if ActiveStorage.replace_on_assign_to_many
              attachment_changes["#{name}"] =
                if Array(attachables).none?
                  ActiveStorage::Attached::Changes::DeleteMany.new("#{name}", self)
                else
                  ActiveStorage::Attached::Changes::CreateMany.new("#{name}", self, attachables, acl: "#{acl}")
                end
            else
              if Array(attachables).any?
                attachment_changes["#{name}"] =
                  ActiveStorage::Attached::Changes::CreateMany.new("#{name}", self, #{name}.blobs + attachables, acl: "#{acl}")
              end
            end
          end
        CODE

        has_many :"#{name}_attachments", -> { where(name: name) }, as: :record, class_name: "ActiveStorage::Attachment", inverse_of: :record, dependent: :destroy do
          def purge
            each(&:purge)
            reset
          end

          def purge_later
            each(&:purge_later)
            reset
          end
        end
        has_many :"#{name}_blobs", through: :"#{name}_attachments", class_name: "ActiveStorage::Blob", source: :blob

        scope :"with_attached_#{name}", -> { includes("#{name}_attachments": :blob) }

        after_save { attachment_changes[name.to_s]&.save }

        after_commit(on: %i[ create update ]) { attachment_changes.delete(name.to_s).try(:upload) }

        ActiveRecord::Reflection.add_attachment_reflection(
          self,
          name,
          ActiveRecord::Reflection.create(:has_many_attached, name, nil, { dependent: dependent }, self)
        )
      end
    end
  end

  ActiveStorage::Blob.class_eval do
    def service_url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline, filename: nil, **options)
      filename = ActiveStorage::Filename.wrap(filename || self.filename)
      expires_in = false if metadata[:acl] == 'public'

      service.url key, expires_in: expires_in, filename: filename, content_type: content_type_for_service_url,
                  disposition: forced_disposition_for_service_url || disposition, **options
    end

    def upload_without_unfurling(io)
      service.upload key, io, checksum: checksum, **service_metadata.merge(acl: metadata[:acl])
    end
  end

  ActiveStorage::Attached::Changes::CreateOne.class_eval do
    attr_reader :name, :record, :attachable, :acl

    def initialize(name, record, attachable, acl: 'public')
      @name, @record, @attachable, @acl = name, record, attachable, acl
    end

    private def find_or_build_blob
      case attachable
      when ActiveStorage::Blob
        attachable
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
        ActiveStorage::Blob.build_after_unfurling \
            io: attachable.open,
            filename: attachable.original_filename,
            content_type: attachable.content_type,
            metadata: { acl: acl }
      when Hash
        ActiveStorage::Blob.build_after_unfurling({ metadata: { acl: acl } }.deep_merge(attachable))
      when String
        ActiveStorage::Blob.find_signed(attachable)
      else
        raise ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}"
      end
    end
  end

  ActiveStorage::Attached::Changes::CreateMany.class_eval do
    attr_reader :name, :record, :attachables, :acl

    def initialize(name, record, attachables, acl: 'public')
      @name, @record, @attachables, @acl = name, record, Array(attachables), acl
    end

    private def build_subchange_from(attachable)
      ActiveStorage::Attached::Changes::CreateOneOfMany.new(name, record, attachable, acl: acl)
    end
  end

  ActiveStorage::Attached.class_eval do
    attr_reader :name, :record, :acl

    def initialize(name, record, acl: 'public')
      @name, @record, @acl = name, record, acl
    end
  end

  if defined?(ActiveStorage::Service)
    ActiveStorage::Service.class_eval do
      def upload(key, io, checksum: nil, acl: 'public')
        raise NotImplementedError
      end
    end
  end

  ActiveStorage::Variant.class_eval do
    def service_url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline)
      metadata = blob.respond_to?(:record) ? blob.record.metadata : blob.metadata
      expires_in = false if metadata[:acl] == 'public'
      service.url key, expires_in: expires_in, disposition: disposition, filename: filename, content_type: content_type
    end

    private def upload(image)
      metadata = blob.respond_to?(:record) ? blob.record.metadata : blob.metadata
      File.open(image.path, "r") { |file| service.upload(key, file, acl: metadata[:acl]) }
    end
  end

  if defined?(ActiveStorage::Service::DiskService)
    ActiveStorage::Service::DiskService.class_eval do
      def upload(key, io, checksum: nil, acl: 'public', **)
        instrument :upload, key: key, checksum: checksum do
          IO.copy_stream(io, make_path_for(key))
          ensure_integrity_of(key, checksum) if checksum
        end
      end
    end
  end

  if defined?(ActiveStorage::Service::S3Service)
    # from activestorage/lib/active_storage/service/s3_service.rb

    ActiveStorage::Service::S3Service.class_eval do
      def upload(key, io, checksum: nil, content_type: nil, acl: 'public', **)
        instrument :upload, key: key, checksum: checksum, acl: acl do
          begin
            object_for(key).put(upload_options.merge(body: io, content_md5: checksum,
                                                     acl: acl == 'public' ? 'public-read' : 'private'))
          rescue Aws::S3::Errors::BadDigest
            raise ActiveStorage::IntegrityError
          end
        end
      end

      def url(key, expires_in:, filename:, disposition:, content_type:)
        instrument :url, key: key, expires_in: expires_in do |payload|
          generated_url = if expires_in == false
                            # cdn url 을 사용할 수 있도록 임시방편으로 정의한 메소드
                            # rails 6.1 버전부터 적용될 아래의 패치에서 이슈가 해결될 예정
                            # https://github.com/rails/rails/pull/34477
                            object_for(key).public_url.gsub(/s3.ap-northeast-2.amazonaws.com\//, "")
                          else
                            object_for(key).presigned_url :get,
                                                          expires_in: expires_in.to_i,
                                                          response_content_disposition: content_disposition_with(
                                                            type: disposition, filename: filename
                                                          ),
                                                          response_content_type: content_type
                          end

          if (cloudfront_alias = Rails.application.credentials.dig(:aws, :cloudfront_alias)).present?
            uri = URI(generated_url)
            uri.host = cloudfront_alias
            generated_url = uri.to_s
          end

          payload[:url] = generated_url

          generated_url
        end
      end

      private
      def object_for(key)
        # ActiveStorage 는 Bucket 의 root dir 가 아닌 폴더에 객체를 업로드하는 것을 지원하지 않고 앞으로도 지원 계획이 없다함
        # 따라서, 아래의 몽키패치 적용
        # https://github.com/rails/rails/issues/32790#issuecomment-487523740
        path = File.join('images', key)
        bucket.object(path)
      end
    end
  end
end

