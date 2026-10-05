//
//  SymbolsListView.swift
//  StockPriceTracker
//
//  The primary screen: a scrollable, sortable list of symbols with live prices,
//  a connection status indicator and a Start/Stop feed control.
//

import SwiftUI

// MARK: - SymbolsListView -

struct SymbolsListView: View {

    @State private var viewModel: SymbolsListViewModel

    init(store: PriceStore) {
        _viewModel = State(initialValue: SymbolsListViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoaded {
                    symbolsList
                } else {
                    ProgressView("Loading symbols…")
                }
            }
            .navigationTitle("Stocks")
            .navigationDestination(for: String.self) { symbol in
                SymbolDetailView(symbol: symbol)
            }
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .top, spacing: 0) { header }
        }
    }

    // MARK: - List -

    private var symbolsList: some View {
        List(viewModel.sortedStocks) { stock in
            NavigationLink(value: stock.symbol) {
                SymbolRowView(stock: stock)
            }
        }
        .listStyle(.plain)
        .animation(.default, value: viewModel.sortOption)
    }

    // MARK: - Header (status + sort) -

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                ConnectionStatusView(status: viewModel.connectionStatus)
                Spacer()
            }
            Picker("Sort by", selection: $viewModel.sortOption) {
                ForEach(StockSortOption.allCases) { option in
                    Text(option.titleKey).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Toolbar -

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: viewModel.toggleFeed) {
                Label(
                    viewModel.isFeedRunning ? "Stop" : "Start",
                    systemImage: viewModel.isFeedRunning ? "stop.fill" : "play.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isFeedRunning ? .red : .green)
        }
    }
}
