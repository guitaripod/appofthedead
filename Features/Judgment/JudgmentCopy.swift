import UIKit
import AppOfTheDeadCore

/// Every word and symbol of the Judgment. The scoring lives in `AppOfTheDeadCore`; this keeps the text in the app's
/// string catalog, keyed by the stable ids of `JudgmentScript`.
enum JudgmentCopy {

    struct Guardian {
        let name: String
        let title: String
        let symbol: String
    }

    static func guardian(for scene: JudgmentScene) -> Guardian {
        switch scene.id {
        case "thoth":
            return Guardian(name: String(localized: "Thoth"), title: String(localized: "Scribe of the Gods"), symbol: "scroll.fill")
        case "charon":
            return Guardian(name: String(localized: "Charon"), title: String(localized: "Ferryman of the Dead"), symbol: "sailboat.fill")
        case "rashnu":
            return Guardian(name: String(localized: "Rashnu"), title: String(localized: "Keeper of the Scales"), symbol: "scalemass.fill")
        case "xolo":
            return Guardian(name: String(localized: "The Xolo"), title: String(localized: "Guide Dog of Mictlan"), symbol: "pawprint.fill")
        case "assessors":
            return Guardian(name: String(localized: "The Forty-Two"), title: String(localized: "Assessors of Ma'at"), symbol: "person.3.sequence.fill")
        case "odin":
            return Guardian(name: String(localized: "Odin"), title: String(localized: "The All-Father"), symbol: "eye.fill")
        case "yama":
            return Guardian(name: String(localized: "Yama"), title: String(localized: "Lord of Death"), symbol: "circle.lefthalf.filled")
        case "hecate":
            return Guardian(name: String(localized: "Hecate"), title: String(localized: "Keeper of the Crossroads"), symbol: "flame.fill")
        default:
            return Guardian(name: String(localized: "Anubis"), title: String(localized: "Guide of Souls"), symbol: "scalemass")
        }
    }

    static func prompt(for scene: JudgmentScene) -> String {
        switch scene.id {
        case "thoth":
            return String(localized: "Thoth unrolls the record of your life. Which line runs longest?")
        case "charon":
            return String(localized: "Charon holds out his hand at the river Styx. The fare is one coin, and you have exactly one.")
        case "rashnu":
            return String(localized: "On the Chinvat Bridge, Rashnu weighs your words. When the truth would cost you dearly, you…")
        case "xolo":
            return String(localized: "In Mictlan a dog carries the dead across the river, but only those who were kind to dogs. A xolo looks up at you.")
        case "assessors":
            return String(localized: "Before forty-two judges you must swear to what you have never done. Which oath can you swear most truly?")
        case "odin":
            return String(localized: "Odin, who hung nine nights on the World Tree to win the runes, asks how your story ends.")
        case "yama":
            return String(localized: "Yama holds up the mirror of karma. It shows what you cling to most.")
        case "hecate":
            return String(localized: "At midnight Hecate waits where three roads meet, a torch in each hand. Which road do you take?")
        default:
            return String(localized: "Anubis lays your heart on the scale. Opposite it, the feather of Ma'at. Any last words?")
        }
    }

    static func answer(_ answer: JudgmentAnswer, in scene: JudgmentScene) -> String {
        switch (scene.id, answer.id) {
        case ("thoth", "promises"): return String(localized: "Promises I kept")
        case ("thoth", "truths"): return String(localized: "Truths I told when lying was easier")
        case ("thoth", "strangers"): return String(localized: "Strangers I helped")
        case ("thoth", "places"): return String(localized: "Places I went, things I learned")
        case ("charon", "pay"): return String(localized: "Pay, and step aboard")
        case ("charon", "give"): return String(localized: "Give it to the weeping shade behind me")
        case ("charon", "haggle"): return String(localized: "Haggle. Everyone has a price.")
        case ("charon", "swim"): return String(localized: "Keep it and swim")
        case ("rashnu", "anyway"): return String(localized: "Tell it anyway")
        case ("rashnu", "gently"): return String(localized: "Tell it gently, and help carry the cost")
        case ("rashnu", "silent"): return String(localized: "Stay silent. Silence isn't lying.")
        case ("rashnu", "bend"): return String(localized: "Bend it a little. Everyone does.")
        case ("xolo", "love"): return String(localized: "I've never met a dog I didn't love")
        case ("xolo", "loyal"): return String(localized: "We understand each other. I'm loyal too.")
        case ("xolo", "cat"): return String(localized: "I'm more of a cat person")
        case ("xolo", "swim"): return String(localized: "I'll swim, thanks")
        case ("assessors", "lied"): return String(localized: "I have not lied")
        case ("assessors", "weep"): return String(localized: "I have not made anyone weep")
        case ("assessors", "greedy"): return String(localized: "I have not been greedy")
        case ("assessors", "arrogant"): return String(localized: "I have not been arrogant")
        case ("odin", "fighting"): return String(localized: "Fighting for something I love")
        case ("odin", "sea"): return String(localized: "Far out at sea")
        case ("odin", "old"): return String(localized: "Old and warm, with family near")
        case ("odin", "secret"): return String(localized: "Chasing one last secret")
        case ("yama", "people"): return String(localized: "The people I love")
        case ("yama", "name"): return String(localized: "My name and what I built")
        case ("yama", "comfort"): return String(localized: "My comforts")
        case ("yama", "nothing"): return String(localized: "Nothing. I'm ready to let go.")
        case ("hecate", "home"): return String(localized: "The lit road home")
        case ("hecate", "dark"): return String(localized: "The dark road no one returns from")
        case ("hecate", "ask"): return String(localized: "I ask her where each one leads")
        case ("hecate", "own"): return String(localized: "None. I make my own.")
        case ("feather", "best"): return String(localized: "I did my best")
        case ("feather", "afraid"): return String(localized: "Weigh it. I'm not afraid.")
        case ("feather", "kind"): return String(localized: "Be gentle, Anubis")
        case ("feather", "osiris"): return String(localized: "I'd like to speak to Osiris")
        default: return answer.id
        }
    }

    static func tradition(_ tradition: JudgmentTradition) -> String {
        switch tradition {
        case .egyptian: return String(localized: "Egyptian")
        case .greek: return String(localized: "Greek")
        case .norse: return String(localized: "Norse")
        case .aztec: return String(localized: "Aztec")
        case .zoroastrian: return String(localized: "Zoroastrian")
        case .buddhist: return String(localized: "Buddhist")
        }
    }

    /// The tradition's color on the night background.
    static func color(for tradition: JudgmentTradition) -> UIColor {
        switch tradition {
        case .egyptian: return UIColor(hex: 0xE5BA5C)
        case .greek: return UIColor(hex: 0xA98BF0)
        case .norse: return UIColor(hex: 0x7FA8F5)
        case .aztec: return UIColor(hex: 0xF07E62)
        case .zoroastrian: return UIColor(hex: 0xF5A04A)
        case .buddhist: return UIColor(hex: 0xF2C76E)
        }
    }

    static func realmName(_ realm: Realm) -> String {
        switch realm {
        case .solarBarque: return String(localized: "Ra's Solar Barque")
        case .fieldOfReeds: return String(localized: "The Field of Reeds")
        case .ammit: return String(localized: "Devoured by Ammit")
        case .elysium: return String(localized: "The Elysian Fields")
        case .asphodel: return String(localized: "The Asphodel Meadows")
        case .tartarus: return String(localized: "Tartarus")
        case .valhalla: return String(localized: "Valhalla")
        case .folkvangr: return String(localized: "Fólkvangr")
        case .ransHall: return String(localized: "Rán's Hall")
        case .hel: return String(localized: "Hel")
        case .nastrond: return String(localized: "Náströnd")
        case .houseOfTheSun: return String(localized: "The House of the Sun")
        case .tlalocan: return String(localized: "Tlalocan")
        case .mictlan: return String(localized: "Mictlan")
        case .houseOfSong: return String(localized: "The House of Song")
        case .hamistagan: return String(localized: "Hamistagan")
        case .houseOfLies: return String(localized: "The House of Lies")
        case .liberation: return String(localized: "The Edge of Liberation")
        case .devaRealm: return String(localized: "The Realm of the Devas")
        case .humanRealm: return String(localized: "A Human Rebirth")
        case .asuraRealm: return String(localized: "The Realm of the Asuras")
        case .hungryGhosts: return String(localized: "The Hungry Ghosts")
        }
    }

    static func realmDescription(_ realm: Realm, verdict: Verdict) -> String {
        switch realm {
        case .solarBarque:
            return String(localized: "Your heart is lighter than the feather. You join Ra in his solar barque, sailing the sky by day and the underworld by night.")
        case .fieldOfReeds:
            return String(localized: "Your heart balances the feather of Ma'at. Osiris welcomes you to Aaru, an Egypt without end where the barley grows taller than a man.")
        case .ammit:
            return String(localized: "Your heart outweighs the feather, and Ammit, part crocodile, part lion, part hippo, devours it. Egyptians were buried with a heart scarab so their heart would not testify against them. Consider one.")
        case .elysium:
            return String(localized: "Rhadamanthus sends you to the Elysian Fields, the meadows of heroes and of those initiated into the Mysteries.")
        case .asphodel:
            return String(localized: "Like most souls, you drift through the Asphodel Meadows, a grey and quiet plain where the dead slowly forget.")
        case .tartarus:
            return String(localized: "Aeacus sees your hubris. Tartarus, as far below Hades as the sky is above the earth, has room for one more.")
        case .valhalla:
            return String(localized: "A Valkyrie chooses you for Valhalla, Odin's hall roofed with shields, to feast and fight until Ragnarök.")
        case .folkvangr:
            return String(localized: "Freyja chooses first, and she chooses you. Half of the battle-slain go to her field, Fólkvangr.")
        case .ransHall:
            return String(localized: "Rán, goddess of the sea, gathers you in her net. The drowned feast in her hall beneath the waves.")
        case .hel:
            return String(localized: "Like most of the Norse dead, you take the road down to Hel, the realm of Loki's daughter. It is quiet, not a punishment.")
        case .nastrond:
            return String(localized: "Oath-breakers wade to Náströnd, the Corpse Shore, where the dragon Níðhöggr gnaws the dead.")
        case .houseOfTheSun:
            return String(localized: "Fallen warriors escort the sun across the sky for four years, then return to the earth as hummingbirds.")
        case .tlalocan:
            return String(localized: "Those taken by water or lightning go to Tlalocan, the rain god's garden of endless spring.")
        case .mictlan:
            return verdict.xoloCarries
                ? String(localized: "Like most souls, you walk four years through the nine levels of Mictlan to rest with Mictlantecuhtli. A xolo carries you over the river.")
                : String(localized: "Like most souls, you walk four years through the nine levels of Mictlan to rest with Mictlantecuhtli. You will be swimming the river yourself.")
        case .houseOfSong:
            return String(localized: "The Chinvat Bridge widens beneath you. Your conscience, Daēnā, meets you as a radiant companion and leads you to the House of Song.")
        case .hamistagan:
            return String(localized: "Your good and evil weigh exactly the same. You wait in Hamistagan, a grey middle place, until the world is made new.")
        case .houseOfLies:
            return String(localized: "The bridge narrows to a blade's edge. Below waits the House of Lies, though in Zoroastrian belief even it ends when the world is renewed.")
        case .liberation:
            return String(localized: "You cling to almost nothing. The wheel of rebirth can barely hold you, and awakening is close.")
        case .devaRealm:
            return String(localized: "Your merit ripens into rebirth among the devas, a bliss so long you forget that it ends.")
        case .humanRealm:
            return String(localized: "You are reborn human: the rarest birth, and the only one from which awakening is possible.")
        case .asuraRealm:
            return String(localized: "Pride carries you to the asuras, demigods forever at war with the gods.")
        case .hungryGhosts:
            return String(localized: "Craving pulls you among the hungry ghosts, with throats like needles and bellies like mountains.")
        }
    }

    static func realmSymbol(_ realm: Realm) -> String {
        switch realm {
        case .solarBarque: return "sun.horizon.fill"
        case .fieldOfReeds: return "leaf.fill"
        case .ammit: return "heart.slash.fill"
        case .elysium: return "sun.max.fill"
        case .asphodel: return "cloud.fog.fill"
        case .tartarus: return "arrow.down.to.line"
        case .valhalla: return "shield.fill"
        case .folkvangr: return "camera.macro"
        case .ransHall: return "water.waves"
        case .hel: return "moon.fill"
        case .nastrond: return "hurricane"
        case .houseOfTheSun: return "sun.max.fill"
        case .tlalocan: return "cloud.rain.fill"
        case .mictlan: return "figure.walk"
        case .houseOfSong: return "music.note"
        case .hamistagan: return "cloud.fill"
        case .houseOfLies: return "flame"
        case .liberation: return "circle.dotted"
        case .devaRealm: return "sparkles"
        case .humanRealm: return "figure.stand"
        case .asuraRealm: return "bolt.fill"
        case .hungryGhosts: return "drop.fill"
        }
    }

    static func archetypeName(_ archetype: SoulArchetype) -> String {
        switch archetype {
        case .featherLight: return String(localized: "The Feather-Light Heart")
        case .lanternBearer: return String(localized: "The Lantern-Bearer")
        case .chosenOfValkyries: return String(localized: "Chosen of the Valkyries")
        case .oathkeeper: return String(localized: "The Oathkeeper")
        case .initiate: return String(localized: "The Initiate")
        case .unbound: return String(localized: "The Unbound")
        case .trickster: return String(localized: "The Trickster at the Gate")
        }
    }

    static func archetypeDescription(_ archetype: SoulArchetype) -> String {
        switch archetype {
        case .featherLight:
            return String(localized: "You would rather pay for the truth than live on a lie. Hearts like yours are why the feather of Ma'at exists.")
        case .lanternBearer:
            return String(localized: "You would give your last coin to a stranger on the shore. Every underworld needs someone carrying a light.")
        case .chosenOfValkyries:
            return String(localized: "You would swim the Styx before paying the toll. The halls of the brave keep a seat for you.")
        case .oathkeeper:
            return String(localized: "Your word outlives you. In every tradition here, a kept promise weighs more than gold.")
        case .initiate:
            return String(localized: "You would take the road no one comes back from, just to see. The Mysteries were made for souls like yours.")
        case .unbound:
            return String(localized: "You hold on to almost nothing, and that is what makes you free. The wheel of rebirth can barely grip you.")
        case .trickster:
            return String(localized: "You would haggle with the ferryman and ask to speak to his manager. Hermes, patron of tricksters, approves.")
        }
    }

    static func archetypeSymbol(_ archetype: SoulArchetype) -> String {
        switch archetype {
        case .featherLight: return "scalemass.fill"
        case .lanternBearer: return "hands.and.sparkles.fill"
        case .chosenOfValkyries: return "shield.lefthalf.filled"
        case .oathkeeper: return "link"
        case .initiate: return "key.fill"
        case .unbound: return "wind"
        case .trickster: return "theatermasks.fill"
        }
    }
}
