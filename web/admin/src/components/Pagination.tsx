import { ChevronLeft, ChevronRight } from "lucide-react"

export interface PaginationProps {
  currentPage: number
  totalItems: number
  pageSize?: number
  onPageChange: (page: number) => void
  itemLabel?: string
  className?: string
  syncNote?: string
}

function getPageNumbers(currentPage: number, totalPages: number): (number | string)[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i + 1)
  }
  if (currentPage <= 4) {
    return [1, 2, 3, 4, 5, "...", totalPages]
  }
  if (currentPage >= totalPages - 3) {
    return [1, "...", totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages]
  }
  return [1, "...", currentPage - 1, currentPage, currentPage + 1, "...", totalPages]
}

export function Pagination({
  currentPage,
  totalItems,
  pageSize = 10,
  onPageChange,
  itemLabel = "mục",
  className = "",
  syncNote,
}: PaginationProps) {
  const totalPages = Math.max(1, Math.ceil(totalItems / pageSize))
  const safePage = Math.min(Math.max(1, currentPage), totalPages)
  const startItem = totalItems === 0 ? 0 : (safePage - 1) * pageSize + 1
  const endItem = Math.min(totalItems, safePage * pageSize)

  const pages = getPageNumbers(safePage, totalPages)

  return (
    <div
      className={`p-4 bg-slate-50/60 border-t border-slate-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs text-slate-500 ${className}`}
    >
      <div className="leading-relaxed">
        <span>
          Hiển thị <strong className="text-slate-800 font-semibold">{startItem}</strong> -{" "}
          <strong className="text-slate-800 font-semibold">{endItem}</strong> trên tổng số{" "}
          <strong className="text-slate-900 font-bold">{totalItems}</strong> {itemLabel}
        </span>
        {syncNote && (
          <span className="text-slate-400 ml-1.5 hidden md:inline">
            • {syncNote}
          </span>
        )}
      </div>

      <div className="flex items-center gap-1 font-medium select-none self-end sm:self-auto">
        {/* Previous page */}
        <button
          type="button"
          disabled={safePage <= 1}
          onClick={() => onPageChange(safePage - 1)}
          aria-label="Trang trước"
          className="w-7 h-7 rounded-md flex items-center justify-center border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer transition shadow-2xs"
        >
          <ChevronLeft size={14} />
        </button>

        {/* Page buttons */}
        {pages.map((p, idx) => {
          if (typeof p === "string") {
            return (
              <span key={`ellipsis-${idx}`} className="px-1 text-slate-400 text-xs">
                ...
              </span>
            )
          }

          const isActive = p === safePage
          return (
            <button
              key={`page-${p}`}
              type="button"
              onClick={() => onPageChange(p)}
              className={`w-7 h-7 rounded-md flex items-center justify-center text-xs transition shadow-2xs ${
                isActive
                  ? "bg-[#C2410C] text-white font-bold border border-[#C2410C]"
                  : "border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 hover:text-slate-900 cursor-pointer"
              }`}
            >
              {p}
            </button>
          )
        })}

        {/* Next page */}
        <button
          type="button"
          disabled={safePage >= totalPages}
          onClick={() => onPageChange(safePage + 1)}
          aria-label="Trang sau"
          className="w-7 h-7 rounded-md flex items-center justify-center border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer transition shadow-2xs"
        >
          <ChevronRight size={14} />
        </button>
      </div>
    </div>
  )
}

