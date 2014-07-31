require 'helper'

describe Epiphy::Repository do
  let(:user1) { User.new(name: 'L') }
  let(:user2) { User.new(name: 'MG') }
  let(:users) { [user1, user2] }

  let(:article1) { Article.new(user_id: user1.id, title: 'Introducing Epiphy::Model', comments_count: '23') }
  let(:article2) { Article.new(user_id: user1.id, title: 'Thread safety',            comments_count: '42') }
  let(:article3) { Article.new(user_id: user2.id, title: 'Love Relationships',       comments_count: '4') }
  
  before do
    UserRepository.collection    = :users
    #ArticleRepository.collection = :articles

    UserRepository.clear
    ArticleRepository.clear
  end

  describe '.collection' do
    it 'returns the collection name' do
      UserRepository.collection.must_equal    :users
      ArticleRepository.collection.must_equal :article
      MovieRepository.collection.must_equal :film
    end
  end

  describe '.persist' do
    describe 'when non persisted' do
      before do
        @createdUser = UserRepository.persist(user)
      end

      let(:user) { User.new(name: 'S') }

      it 'is created' do
        id  = @createdUser
        # mocking id of new created object for comparing
        # we only need to compare the value, the id isn't need to compare
        user.id = id
        UserRepository.find(id).must_equal(user)
      end
    end

    describe 'when already persisted' do
      before do
        UserRepository.create(user1)

        user1.name = 'Luke'
        user1.age = 29
        UserRepository.persist(user1)
      end

      let(:id) { user1.id }

      it 'is updated' do
        UserRepository.find(id).must_equal(user1)
      end
    end
  end

  describe '.create' do
    before do
      # Cleanup
      #UserRepository.clear
      UserRepository.create(user1)
      UserRepository.create(user2)
    end

    it 'persist entities' do
      UserRepository.all.each do |u|
        users.must_include u
      end
    end

    it 'creates different kind of entities' do
      ArticleRepository.create(article1)
      ArticleRepository.all.must_equal([article1])
    end

    it 'does nothing when already persisted' do
      id = user1.id

      UserRepository.create(user1)
      user1.id.must_equal id
    end
  end

  describe '.update' do
    before do
      UserRepository.create(user1)
    end

    let(:id) { user1.id }

    it 'updates entities' do
      user = User.new(name: 'Luca')
      user.id = id

      UserRepository.update(user)

      u = UserRepository.find(id)
      u.name.must_equal('Luca')
    end

    it 'raises an error when not persisted' do
      -> { UserRepository.update(user2) }.must_raise(Epiphy::Model::NonPersistedEntityError)
    end
  end

  describe '.delete' do
    before do
      UserRepository.create(user)
      UserRepository.delete(user)
    end

    let(:user) { User.new(name: 'D') }

    it 'delete entity' do
      # Don't use to_a on big table
      UserRepository.all.to_a.wont_include(user)
    end

    it 'raises error when the given entity is not persisted' do
      -> { UserRepository.delete(user2) }.must_raise(Epiphy::Model::NonPersistedEntityError)
    end
  end

  describe '.all' do
    describe 'without data' do
      it 'returns an empty collection' do
        UserRepository.all.must_be_empty
      end
    end

    describe 'with data' do
      before do
        UserRepository.create(user1)
        UserRepository.create(user2)
      end

      it 'returns all the entities' do
        # RethinkDB isn't guarantee an order without a explicit orderBy 
        # Workaround to make the test pass until we fix the underlying issue.
        # Probably auto include a field in entity for timestamp or so
        UserRepository.all.each do |u|
          users.must_include u
        end
      end
    end

    describe "with a given block " do
      it "iterator the result" do
        UserRepository.all do |u|
          users.must_include u
        end
      end
    end
  end

  describe '.find' do
    describe 'without data' do
      it 'raises error' do
        -> { UserRepository.find(1) }.must_raise(Epiphy::Model::EntityNotFound)
      end
    end

    describe 'with data' do
      before do
        TestPrimaryKey = Struct.new(:id) do
          def to_s
            id
          end
        end

        UserRepository.create(user1)
        UserRepository.create(user2)

        ArticleRepository.create(article1)
      end

      after do
        Object.send(:remove_const, :TestPrimaryKey)
      end

      it 'returns the entity associated with the given id' do
        UserRepository.find(user1.id).must_equal(user1)
      end

      it 'accepts a string as argument' do
        UserRepository.find(user2.id.to_s).must_equal(user2)
      end

      it 'accepts an object that can be force to a String' do
        id = TestPrimaryKey.new(user2.id)
        UserRepository.find(id).must_equal(user2)
      end

      #it "doesn't assign a value to unmapped attributes" do
        #ArticleRepository.find(article1.id).unmapped_attribute.must_be_nil
      #end

      it "raises error when the given id isn't associated with any entity" do
        -> { UserRepository.find(1_000_000) }.must_raise(Epiphy::Model::EntityNotFound)
      end
    end
  end

  #describe '.first' do
    #describe 'without data' do
      #it 'returns nil' do
        #UserRepository.first.must_be_nil
      #end
    #end

    #describe 'with data' do
      #before do
        #UserRepository.create(user1)
        #UserRepository.create(user3)
      #end

      #it 'returns first record' do
        #UserRepository.first.must_equal(user1)
      #end
    #end
  #end

  #describe '.last' do
    #describe 'without data' do
      #it 'returns nil' do
        #UserRepository.last.must_be_nil
      #end
    #end

    #describe 'with data' do
      #before do
        #UserRepository.create(user1)
        #UserRepository.create(user2)
      #end

      #it 'returns last record' do
        #UserRepository.last.must_equal(user2)
      #end
    #end
  #end

  describe '.clear' do
    describe 'without data' do
      it 'removes all the records' do
        UserRepository.clear
        UserRepository.all.must_be_empty
      end
    end

    describe 'with data' do
      before do
        UserRepository.create(user1)
        UserRepository.create(user2)
      end

      it 'removes all the records' do
        UserRepository.clear
        UserRepository.all.must_be_empty
      end
    end
  end

  describe 'querying' do
    before do
      UserRepository.create(user1)
      ArticleRepository.create(article1)
      ArticleRepository.create(article2)
      ArticleRepository.create(article3)
    end

    it 'defines custom finders' do
      actual = ArticleRepository.by_user(user1)
      actual.each do |i|
        [article1, article2].must_include i
      end
    end

    #it 'return a single entity for corresponding query' do
    it 'return an array of Entity' do
      highest_article = Article.new title: 'test', rank: 99999
      second_article  = Article.new title: 'test', rank: 99998
      ArticleRepository.create highest_article
      ArticleRepository.create second_article
      actual = ArticleRepository.highest_rank
      actual.must_equal [highest_article]
    end

    #if adapter_name == :sql
      #it 'combines queries' do
        #actual = ArticleRepository.rank_by_user(user1)
        #actual.all.must_equal [article2, article1]
      #end

      #it 'negates a query' do
        #actual = ArticleRepository.not_by_user(user1)
        #actual.all.must_equal []
      #end
    #end
  end

  describe 'find_by' do
    before do
      UserRepository.create(user1)
    end

    it 'find the entity with a field' do
      actual = UserRepository.find_by(name: user1.name)
      actual.name.must_equal user1.name  
    end

  end

  describe 'count' do
    before do
      UserRepository.create(user1)
      UserRepository.create(user2)
      UserRepository.create(User.new(:age =>25, :name => 'K'))
    end
    
    it 'tell us the collection length' do
      UserRepository.count.must_equal 3
    end
  end

end
