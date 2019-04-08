import Foundation

enum GameError: String {
    case incorrectGameState = "incorrectGameState"
    case playerAlreadyInGame = "playerAlreadyInGame"
    case playersNotCloseEnough = "playersNotCloseEnough"
    case tagReceiverNotInGame = "tagReceiverNotInGame"
    case serverError = "serverError"
    case gameDoesNotExist = "gameDoesNotExist"
    case tooManyTeams = "tooManyTeams"
    case tooManyPlayersOnTeam = "tooManyPlayersOnTeam"
    case playerNotInBounds = "playerNotInBounds"
    case boundaryAlreadyExists = "boundaryAlreadyExists"
    case playerDoesNotHavePermission = "playerDoesNotHavePermission"
    case onIncorrectSide = "onIncorrectSide"
    case cannotBeOnSameTeam = "cannotBeOnSameTeam"
}
