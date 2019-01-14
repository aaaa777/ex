module MessageFormat
  class Message
    def initialize(attribute = {})
      @language = :ja unless attribute[:language]
      @language = attribute[:language] if attribute[:language]
    end

    def error(error_type, attribute = {})
      attribute[:language] = @language
      MessageFormat::Message::Error.new(error_type, attribute)
    end


    class Error
      def initialize(error_type, argument = {user_name: 'none', language: :ja, argument: 'none'})
        @user_name = argument[:user_name]
        @error_type = error_type
        @language = argument[:language]
        @invalid_argument = argument[:argument]
      end
      
      def user_name
        @user_name
      end
      
      def error_type
        @error_type
      end
      
      def language
        @language
      end
      
      def output
        case @error_type
        when :player_not_found_api
          case @language
          when :ja
            ":warning: **[エラー]:**プレイヤー:`#{@user_name}`が見つかりませんでした"
          when :en
            ":warning: **[error]:**player:`#{@user_name}` not found"
          end
        when :player_not_found_me
          case @language
          when :ja
            ":warning: **[エラー]:**プレイヤー:`#{@user_name}`はオプション`me`で登録されていません！`/stats #{@user_name} me`でプレイヤー名を登録してください"
          when :en
            ":warning: **[error]:**player:`#{@user_name}` is not registered! type `/stats #{@user_name} me` first"
          end
        when :over_24_characters
          case @language
          when :ja
            ":warning: **[エラー]:**プレイヤー名は3文字以上24文字以下である必要があります"
          when :en
            ":warning: **[error]:**player name must be under 24 and below character"
          end
        when :include_not_ascii
          case @language
          when :ja
            ":warning: **[エラー]:**使用可能なプレイヤー名は`A-Z,a-z,0-9,_`のみです"
          when :en
            ":warning: **[error]:**Available characters are only `A-Z,a-z,0-9,_`"
          end
        when :invalid_player
          case @language
          when :ja
            ""
          when :en
            ""
          end
        when :invalid_argument
          case @language
          when :ja
            ":warning: **[エラー]:**不明なオプション:`#{@invalid_argument}`が指定されました"
          when :en
            ":warning: **[error]:**invalid argument:`#{@invalid_argument}`"
          end
        
        
        else
          raise
        end
      end
    end
  end
end