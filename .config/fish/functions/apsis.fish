# The apsis command: doctor, update, rollback, version, newer, check and setup are Apsis's own; anything else is git on the ~/.apsis repo.
# Edit: add a case here for a new subcommand.

function apsis --wraps='git --git-dir=$HOME/.apsis --work-tree=$HOME' --description 'Apsis commands, otherwise git on the Apsis repo'
    switch "$argv[1]"
        case doctor
            sh $HOME/.config/hypr/scripts/apsis-doctor.sh $argv[2..-1]
            return $status
        case update rollback version newer
            sh $HOME/.config/apsis/update.sh $argv
            return $status
        case check
            sh $HOME/.config/apsis/setup.sh --check
            return $status
        case setup
            sh $HOME/.config/apsis/setup.sh $argv[2..-1]
            return $status
    end
    git --git-dir=$HOME/.apsis --work-tree=$HOME $argv
end
