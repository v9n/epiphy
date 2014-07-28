class User
  include Epiphy::Entity
  self.attributes = :name, :age
end

class Article
  include Epiphy::Entity
  self.attributes = :user_id, :unmapped_attribute, :title, :comments_count
end

class CustomUserRepository
  include Epiphy::Repository
end

class UserRepository
  include Epiphy::Repository
end

class ArticleRepository
  include Epiphy::Repository

  def self.rank
    query do
      desc(:comments_count)
    end
  end

  def self.by_user(user)
    query do
      where(user_id: user.id)
    end
  end

  def self.not_by_user(user)
    exclude by_user(user)
  end

  def self.rank_by_user(user)
    rank.by_user(user)
  end
end

class MovieRepository
  include Epiphy::Repository
  self.collection= :film
end
