import Core
import SwiftUI

extension NFCEditorView {
    struct NFCCard: View {
        @Binding var item: ArchiveItem

        var mifareType: String {
            guard let typeProperty = item.properties.first(
                where: { $0.key == "Mifare Classic type" }
            ) else {
                return "??"
            }
            return typeProperty.value
        }

        // FIXME: buggy padding

        var paddingLeading: Double {
            switch UIScreen.main.bounds.width {
            case 320: return 3
            case 414: return 24
            default: return 12
            }
        }

        var paddingTrailing: Double {
            switch UIScreen.main.bounds.width {
            case 320: return 4
            case 414: return 34
            default: return 17
            }
        }

        var body: some View {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text("MIFARE Classic \(mifareType)")
                            .font(.system(size: 12, weight: .heavy))

                        Image("NFCCardWaves")
                            .frame(width: 24, height: 24)
                    }
                    .padding(.top, 17)

                    Image("NFCCardInfo")
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 31)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("UID:")
                                .fontWeight(.bold)
                            Text(item.properties["UID"] ?? "")
                                .fontWeight(.medium)
                        }

                        HStack(spacing: 23) {
                            HStack {
                                Text("ATQA:")
                                    .fontWeight(.bold)
                                Text(item.properties["ATQA"] ?? "")
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("SAK:")
                                    .fontWeight(.bold)
                                Text(item.properties["SAK"] ?? "")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .font(.system(size: 10))
                    .padding(.top, 32)
                    .padding(.bottom, 13)
                }
                .padding(.leading, paddingLeading)
                .padding(.trailing, paddingTrailing)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .background {
                Image("NFCCard")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}