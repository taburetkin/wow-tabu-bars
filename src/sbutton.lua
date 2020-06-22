local A, _, L, Cache = Tabu:Spread(...);
--local microIconsRoot = "Interface\\Buttons\\UI-MicroButton-";
A.SButton = {
	_ensure = function() 

		local iconsPath = "Interface\\AddOns\\"..A.OriginalName.."\\Media\\Icons\\";
		

		if (A.SButton.buttons) then
			return;
		end

		local btns = {
			{
				id = "system-helpframe",
				group = "system",
				label = "Customer support button",
				proto = {
					type = "special-button",
					typeName = "system-helpframe",
					attrs = {
						["*type1"] = "macro",
						["macrotext"] = "/run ToggleHelpFrame()"
					},
					info = {
						icon = iconsPath .. "Question-64x64", --, --microIconsRoot .. "Help"
						--twoChars = "H"
					}
				}
			},
			{
				id = "system-mainmenu",
				group = "system",
				label = "Main menu button",
				proto = {
					type = "special-button",
					typeName = "system-mainmenu",
					attrs = {
						["*type1"] = "macro",
						["macrotext"] = "/run GameMenuFrame:Show()"
					},
					info = {
						icon = iconsPath .. "Computer-64x64", --, --microIconsRoot .. "Help"
						--twoChars = "M"
					}
				}
			},
			{
				id = "system-worldmap",
				group = "system",
				label = "World map button",
				proto = {
					type = "special-button",
					typeName = "system-worldmap",
					attrs = {
						["*type1"] = "macro",
						["macrotext"] = "/run ToggleWorldMap()"
					},
					info = {
						icon = iconsPath .. "Earth-64x64", --false, --microIconsRoot .. "Help"
						--twoChars = "W"
					}
				}
			},
			{
				id = "system-socials",
				group = "system",
				label = "Socials button",
				proto = {
					type = "special-button",
					typeName = "system-socials",
					attrs = {
						["*type1"] = "macro",
						["macrotext"] = "/run ToggleFriendsFrame()"
					},
					info = {
						icon = iconsPath .. "Socials-64x64", --false, --microIconsRoot .. "Help"
						--twoChars = "So"
					}
				}
			},	
			{
				id = "system-questlog",
				group = "system",
				label = "Quest log button",
				proto = {
					type = "special-button",
					typeName = "system-questlog",
					attrs = {
						["*type1"] = "macro",
						["macrotext"] = "/run ToggleQuestLog()"
					},
					info = {
						icon = iconsPath .. "Quest-64x64", --false, --microIconsRoot .. "Help"
						--twoChars = "Q"
					}
				}
			},	
			{
				id = "system-talents",
				group = "system",
				label = "Talents button",
				proto = {
					type = "special-button",
					typeName = "system-talents",
					attrs = {
						["*type1"] = "macro",
						["macrotext"] = "/run ToggleTalentFrame()"
					},
					info = {
						icon = 132222, --false, --microIconsRoot .. "Help"
						--twoChars = "T"
					}
				}
			},	
			{
				id = "system-spellbook",
				group = "system",
				label = "Spell book button",
				proto = {
					type = "special-button",
					typeName = "system-spellbook",
					attrs = {
						["*type1"] = "macro",
						["macrotext"] = "/run ToggleSpellBook(BOOKTYPE_SPELL)"
					},
					info = {
						icon = iconsPath .. "Spellbook-64x64", --false, --microIconsRoot .. "Help"
						--twoChars = "Sp"
					}
				}
			},
			{
				id = "system-character",
				group = "system",
				label = "Character button",
				proto = {
					type = "special-button",
					typeName = "system-character",
					attrs = {
						["*type1"] = "macro",
						["macrotext"] = "/run ToggleCharacter('PaperDollFrame')"
					},
					info = {
						icon = function(iconFrame)
							--iconFrame:Show();
							SetPortraitTexture(iconFrame, "player");
							if (iconFrame._portraitChangeListener) then return end;
							iconFrame._portraitChangeListener = true;
							A.Bus.On("UNIT_PORTRAIT_UPDATE", function(unitName,a2,a3) 
								if (unitName == "player") then
									SetPortraitTexture(iconFrame, "player");
								end
							end)

						end,
						--twoChars = "C"
					}
				}
			},															
		}


		A.SButton.buttons = btns;
		A.SButton.buttonsById = {};
		for x,btn in ipairs(btns) do
			A.SButton.buttonsById[btn.id] = btn;
		end
	end,
	GetButtons = function()
		A.SButton._ensure();
		return A.SButton.buttons;
	end,
	GetButton = function(id)
		A.SButton._ensure();		
		return A.SButton.buttonsById[id];
	end,
	GetButtonProto = function(id)
		A.SButton._ensure();
		local btn = A.SButton.GetButton(id);
		if (btn) then
			local res = _.cloneTable(btn.proto);
			res.attrs.special = true;
			return res;
		end
	end

}
