//
//  SurveyTask.swift
//  Camelot
//
//  Created by Jill Sue on 3/6/17.
//  Copyright © 2017 Jill Sue. All rights reserved.
//

import Foundation
import ResearchKit

public var SurveyTask: ORKOrderedTask {
    
    var steps = [ORKStep]()
    
    let instructionStep = ORKInstructionStep(identifier: "IntroStep")
    instructionStep.title = "Symptom Log"
    instructionStep.text = "Thanks for logging in! Please click on NEXT to answer the questions."
    steps += [instructionStep]
    
    //TODO: add name question
    
    let questQuestionStepTitle = "Which symptoms are you feeling right now?"
    let textChoices = [
        ORKTextChoice(text: "Nausea", value: 0 as NSCoding & NSCopying & NSObjectProtocol),
        ORKTextChoice(text: "Vomitting", value: 1 as NSCoding & NSCopying & NSObjectProtocol),
        ORKTextChoice(text: "Dizziness", value: 2 as NSCoding & NSCopying & NSObjectProtocol),
        ORKTextChoice(text: "Memory Loss", value: 3 as NSCoding & NSCopying & NSObjectProtocol),
        ORKTextChoice(text: "Pain", value: 4 as NSCoding & NSCopying & NSObjectProtocol)
    ]
    let questAnswerFormat: ORKTextChoiceAnswerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .multipleChoice, textChoices: textChoices)
    let questQuestionStep = ORKQuestionStep(identifier: "SymptomsRightNow", title: questQuestionStepTitle, answer: questAnswerFormat)
    steps += [questQuestionStep]
    
    let nameAnswerFormat = ORKTextAnswerFormat(maximumLength: 20)
    nameAnswerFormat.multipleLines = false
    let nameQuestionStepTitle = "Any other symptoms not listed above?"
    let nameQuestionStep = ORKQuestionStep(identifier: "OtherSymptoms", title: nameQuestionStepTitle, answer: nameAnswerFormat)
    steps += [nameQuestionStep]
    
    let questQuestionStepTitleThree = "How many significant social interactions have you had so far today?"
    let textChoicesThree = [
        ORKTextChoice(text: "0", value: 0 as NSCoding & NSCopying & NSObjectProtocol),
        ORKTextChoice(text: "1-3", value: 1 as NSCoding & NSCopying & NSObjectProtocol),
        ORKTextChoice(text: "4-6", value: 2 as NSCoding & NSCopying & NSObjectProtocol),
        ORKTextChoice(text: "7 or more", value: 3 as NSCoding & NSCopying & NSObjectProtocol)
    ]
    let questAnswerFormatThree: ORKTextChoiceAnswerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .multipleChoice, textChoices: textChoicesThree)
    let questQuestionStepThree = ORKQuestionStep(identifier: "SocialInteraction", title: questQuestionStepTitleThree, answer: questAnswerFormatThree)
    steps += [questQuestionStepThree]
    
    let nameAnswerFormatFour = ORKTextAnswerFormat(maximumLength: 100)
    nameAnswerFormat.multipleLines = false
    let nameQuestionStepTitleFour = "If you'd like to include any other details, please do so here."
    let nameQuestionStepFour = ORKQuestionStep(identifier: "OtherDetails", title: nameQuestionStepTitleFour, answer: nameAnswerFormatFour)
    steps += [nameQuestionStepFour]
    
    let summaryStep = ORKCompletionStep(identifier: "SummaryStep")
    summaryStep.title = "Thank you!"
    summaryStep.text = "Your symptoms have been recorded."
    steps += [summaryStep]
    
    return ORKOrderedTask(identifier: "SurveyTask", steps: steps)
}




