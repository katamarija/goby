module Goby

  # Functions that handle commands on the "world map."
  module WorldCommand

    # String literal providing default commands.
    DEFAULT_COMMANDS =
  %{     Command          Purpose

        w (↑)
  a (←) s (↓) d (→)       Movement

          help      Show the help menu
         map       Print the map
         supermap       Print all the map
          inv         Check inventory
        status         Show player status
      use [item]      Use the specified item
      drop [item]        Drop the specified item
     equip [item]      Equip the specified item
    unequip [item]    Unequip the specified item
         save              Save the game
         quit               Quit the game

  }

    # String literal for the special commands header.
    SPECIAL_COMMANDS_HEADER = "* Special commands: "
    # Message for when the player tries to drop a non-existent item.
    NO_ITEM_DROP_ERROR = "You can't drop what you don't have!\n\n"

    # Prints the commands that are available everywhere.
    def display_default_commands
      print DEFAULT_COMMANDS
    end

    # Prints the commands that are tile-specific.
    #
    # @param [Player] player the player who wants to see the special commands.
    def display_special_commands(player)
      events = player.location.map.tiles[player.location.coords.first][player.location.coords.second].events
      if events.nonempty? && events.any? { |event| event.visible }

        print SPECIAL_COMMANDS_HEADER + (events.reduce([]) do |commands, event|
          commands << event.command if event.visible
          commands
        end.join(', ')) + "\n\n"
      end
    end

    # Prints the default and special (tile-specific) commands.
    #
    # @param [Player] player the player who needs help.
    def help(player)
      display_default_commands
      display_special_commands(player)
    end

    # Describes the tile to the player after each move.
    #
    # @param [Player] player the player who needs the tile description.
    def describe_tile(player)
      tile = player.location.map.tiles[player.location.coords.first][player.location.coords.second]
      events = tile.events

      player.print_minimap
      print "#{tile.description}\n\n"
      display_special_commands(player)
    end

    # Handles the player's input and executes the appropriate action.
    #
    # @param [String] command the player's entire command input.
    # @param [Player] player the player using the command.
    def interpret_command(command, player)
      command = command.downcase
      return if command.eql?("quit")

      words = command.split()

      # Default commands that take multiple "arguments" (words).
      if (words.size > 1)

        # TODO: this chunk could be a private function.
        # Determine the name of the second "argument."
        name = words[1]
        for i in 2..(words.size - 1) do
          name << " " << words[i]
        end

        # Determine the appropriate command to use.
        # TODO: some of those help messages should be string literals.
        if words[0].casecmp("drop").zero?
          index = player.has_item(name)
          if index && !player.inventory[index].first.disposable
            print "You cannot drop that item.\n\n"
          elsif index
            # TODO: Perhaps the player should be allowed to specify
            #       how many of the Item to drop.
            item = player.inventory[index].first
            player.remove_item(item, 1)
            print "You have dropped #{item}.\n\n"
          else
            print NO_ITEM_DROP_ERROR
          end
          return
        elsif words[0].casecmp("equip").zero?
          player.equip_item(name); return
        elsif words[0].casecmp("unequip").zero?
          player.unequip_item(name); return
        elsif words[0].casecmp("use").zero?
          player.use_item(name, player); return
        end
      end

      # TODO: map command input to functions? Maybe this can
      #       also be done with the multiple-word commands?

      case command
      when "w"
        player.move_up; return
      when "a"
        player.move_left; return
      when "s"
        player.move_down; return
      when "d"
        player.move_right; return
      when "help"
        help(player); return
      when "map"
        player.print_map; return
      when "supermap"
        player.print_map(true); return
      when "inv"
        player.print_inventory; return
      when "status"
        player.print_status; return
      when "save"
        save_game(player, "player.yaml"); return
      end

      # Other commands.
      events = player.location.map.tiles[player.location.coords.first][player.location.coords.second].events
      events.each do |event|
        if (event.visible && words[0] && words[0].casecmp(event.command).zero?)
          event.run(player)
          return
        end
      end

      # Text for incorrect commands.
      # TODO: Add string literal for this.
      puts "That isn't an available command at this time."
      print "Type 'help' for a list of available commands.\n\n"

    end
  end

end
