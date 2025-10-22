//
//  ResearchService.swift
//  Wutzup
//
//  Protocol for conducting web research with AI summarization
//

import Foundation

protocol ResearchService {
    /// Conducts research on a given prompt by searching the web and summarizing results
    /// - Parameter prompt: The research question or topic
    /// - Returns: A summary of the research findings
    /// - Throws: Error if research fails
    func conductResearch(prompt: String) async throws -> String
}

