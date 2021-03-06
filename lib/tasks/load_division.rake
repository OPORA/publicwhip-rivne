namespace :load_division do
  desc "Load votes"
  task :votes, [:from_date, :to_date] => :environment do |t, args|
    load_votes = JSON.load(open("http://rivnevoted.oporaua.org/votes_events/"))
    save_votes = Division.pluck(:date).uniq.to_a.map{|d| d.strftime('%Y-%m-%d')}
    date_votes = load_votes - save_votes
    date_votes.each do |date|
      divisions = JSON.load(open("http://rivnevoted.oporaua.org/votes_events/#{date}.json"))
      divisions.each do |d|
        p d[0]["name"]
            date_vote =  DateTime.parse(d[0]["date_vote"]).strftime("%F")
            mps =  Mp.where("? >= start_date and end_date >= ?", date, date).to_a.uniq(&:deputy_id)
        division = Division.find_or_create_by(
            date: date_vote,
            number: d[0]["number"],
            name: d[0]["name"],
            clock_time: DateTime.parse(d[0]["date_vote"]).strftime("%T"),
            result: d[0]["option"]
        )
        ActiveRecord::Base.transaction do
          division.votes.destroy_all
        end
        votes = []
          d[1]["votes"].each do |v|
            #p v["voter_id"]
            #next if mps.find{|m| m["deputy_id"] == v["voter_id"] }.nil?
            mp = mps.find{|m| m["deputy_id"] == v["voter_id"] }.id
            votes << {deputy_id: mp, vote: v["result"]}
          end
          ActiveRecord::Base.transaction do  
            division.votes.create(votes)
          end  
      end
    end
  end
end