class DeleteAllScoringComments < ActiveRecord::Migration[5.2]
  def change
    ScoringComment.delete_all
  end
end
