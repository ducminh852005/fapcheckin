import { BookOpen, Clock3, GraduationCap, LoaderCircle, Plus, Search, UserPlus, Users, X } from "lucide-react"
import { useCallback, useMemo, useState } from "react"
import { Button, Field, PageHeader } from "../components/ui"
import { Pagination } from "../components/Pagination"
import { readError, useAsyncData } from "../hooks/useAsyncData"
import {
  assignStudentToClass,
  createClass,
  listAcademicData,
  listAcademicDataPaginated,
  listClassAssignmentData,
  listClassTeachers,
  type ClassRow,
  type EnrollmentRow,
  type StudentOption,
  type SubjectRow,
  type SlotRow,
  type TeacherOption,
} from "../repositories/academicRepository"

type ClassForm = {
  classCode: string
  subjectCode: string
  teacherMemberCode: string
  slotCode: string
  room: string
  capacity: string
}
const emptyClass: ClassForm = {
  classCode: "",
  subjectCode: "",
  teacherMemberCode: "",
  slotCode: "",
  room: "",
  capacity: "40",
}

export function AcademicEnrollmentManagement() {
  const [tab, setTab] = useState<"classes" | "subjects" | "slots">("classes")
  const [search, setSearch] = useState("")
  const [classPage, setClassPage] = useState(1)
  const [subjectPage, setSubjectPage] = useState(1)
  const [slotPage, setSlotPage] = useState(1)

  const currentPage = tab === "classes" ? classPage : tab === "subjects" ? subjectPage : slotPage
  const loader = useCallback(
    () =>
      listAcademicDataPaginated({
        tab,
        page: currentPage,
        pageSize: 10,
        search,
      }),
    [tab, currentPage, search]
  )
  const { data, loading, error, reload } = useAsyncData(loader)

  const [selected, setSelected] = useState<ClassRow | null>(null)
  const [students, setStudents] = useState<StudentOption[]>([])
  const [enrollments, setEnrollments] = useState<EnrollmentRow[]>([])
  const [studentId, setStudentId] = useState("")
  const [studentSearch, setStudentSearch] = useState("")
  const [rosterLoading, setRosterLoading] = useState(false)
  const [busy, setBusy] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [createOpen, setCreateOpen] = useState(false)
  const [teachers, setTeachers] = useState<TeacherOption[]>([])
  const [modalOptions, setModalOptions] = useState<{ subjects: SubjectRow[]; slots: SlotRow[] }>({
    subjects: [],
    slots: [],
  })
  const [classForm, setClassForm] = useState<ClassForm>(emptyClass)

  const classes = data?.classes ?? []
  const subjects = data?.subjects ?? []
  const slots = data?.slots ?? []

  const enrolledRolls = useMemo(() => new Set(enrollments.map((item) => item.rollNumber)), [enrollments])
  const candidates = useMemo(
    () =>
      students.filter(
        (student) =>
          !enrolledRolls.has(student.rollNumber) &&
          `${student.fullName} ${student.rollNumber} ${student.email}`
            .toLowerCase()
            .includes(studentSearch.toLowerCase())
      ),
    [students, enrolledRolls, studentSearch]
  )

  const loadRoster = async (classCode: string) => {
    setRosterLoading(true)
    setActionError(null)
    try {
      const result = await listClassAssignmentData(classCode)
      setStudents(result.students)
      setEnrollments(result.enrollments)
    } catch (reason) {
      setActionError(readError(reason))
    } finally {
      setRosterLoading(false)
    }
  }

  const openClass = (row: ClassRow) => {
    setSelected(row)
    setStudentId("")
    setStudentSearch("")
    setMessage(null)
    void loadRoster(row.classCode)
  }

  const assign = async () => {
    if (!selected) return
    const student = students.find((item) => item.id === studentId)
    if (!student) return setActionError("Vui lòng chọn sinh viên cần thêm.")
    setBusy(true)
    setActionError(null)
    setMessage(null)
    try {
      await assignStudentToClass(selected.classCode, student)
      setMessage(`Đã thêm ${student.fullName || student.rollNumber} vào lớp.`)
      setStudentId("")
      setSelected({ ...selected, studentCount: selected.studentCount + 1 })
      await loadRoster(selected.classCode)
      reload()
    } catch (reason) {
      setActionError(readError(reason))
    } finally {
      setBusy(false)
    }
  }

  const openCreate = async () => {
    setCreateOpen(true)
    setActionError(null)
    setMessage(null)
    try {
      const [t, academic] = await Promise.all([listClassTeachers(), listAcademicData()])
      setTeachers(t)
      setModalOptions({ subjects: academic.subjects, slots: academic.slots })
    } catch (reason) {
      setActionError(readError(reason))
    }
  }

  const saveClass = async () => {
    setBusy(true)
    setActionError(null)
    try {
      await createClass({ ...classForm, capacity: Number(classForm.capacity) })
      setCreateOpen(false)
      setClassForm(emptyClass)
      setMessage("Đã tạo lớp học và phân công lịch.")
      reload()
    } catch (reason) {
      setActionError(readError(reason))
    } finally {
      setBusy(false)
    }
  }

  return (
    <>
      <PageHeader
        title="Dữ liệu học vụ"
        description="Dữ liệu canonical đang được lịch học và điểm danh sử dụng."
        actions={
          <div className="flex items-center gap-2.5">
            <button
              type="button"
              onClick={() => void openCreate()}
              className="h-9 flex items-center gap-2 px-4 bg-[#C2410C] hover:bg-[#9A3412] text-white rounded-xl text-xs font-semibold shadow-xs transition cursor-pointer"
            >
              <Plus size={14} />
              <span>Thêm lớp học</span>
            </button>
          </div>
        }
      />
      {error && (
        <section className="data-error">
          <b>Không thể tải dữ liệu học vụ</b>
          <span>{error}</span>
        </section>
      )}
      {message && !selected && (
        <section className="data-success">
          <b>Thành công</b>
          <span>{message}</span>
        </section>
      )}
      <div className="tabs">
        <button className={tab === "classes" ? "active" : ""} onClick={() => setTab("classes")}>
          Lớp học <span>{data?.totalClasses ?? 0}</span>
        </button>
        <button className={tab === "subjects" ? "active" : ""} onClick={() => setTab("subjects")}>
          Môn học <span>{data?.totalSubjects ?? 0}</span>
        </button>
        <button className={tab === "slots" ? "active" : ""} onClick={() => setTab("slots")}>
          Khung giờ <span>{data?.totalSlots ?? 0}</span>
        </button>
      </div>
      <article className="card table-card">
        <div className="table-toolbar">
          <label className="search-box">
            <Search size={18} />
            <input
              value={search}
              onChange={(event) => {
                setSearch(event.target.value)
                setClassPage(1)
                setSubjectPage(1)
                setSlotPage(1)
              }}
              placeholder="Tìm trong dữ liệu học vụ..."
            />
          </label>
          <span className="source-chip">Nguồn: {tab}</span>
        </div>
        {loading ? (
          <div className="data-loading">
            <LoaderCircle className="spin" size={24} />
            <span>Đang tải dữ liệu...</span>
          </div>
        ) : tab === "classes" ? (
          <>
            <ClassesTable rows={classes} open={openClass} />
            <Pagination
              currentPage={classPage}
              totalItems={data?.totalClasses ?? 0}
              pageSize={10}
              onPageChange={setClassPage}
              itemLabel="lớp học"
              syncNote="FAP Edu Core"
            />
          </>
        ) : tab === "subjects" ? (
          <>
            <SubjectsTable rows={subjects} />
            <Pagination
              currentPage={subjectPage}
              totalItems={data?.totalSubjects ?? 0}
              pageSize={10}
              onPageChange={setSubjectPage}
              itemLabel="môn học"
              syncNote="FAP Edu Core"
            />
          </>
        ) : (
          <>
            <SlotsTable rows={slots} />
            <Pagination
              currentPage={slotPage}
              totalItems={data?.totalSlots ?? 0}
              pageSize={10}
              onPageChange={setSlotPage}
              itemLabel="khung giờ học"
              syncNote="FAP Edu Core"
            />
          </>
        )}
      </article>
      {selected && (
        <ClassDrawer
          selected={selected}
          students={students}
          enrollments={enrollments}
          candidates={candidates}
          studentId={studentId}
          setStudentId={setStudentId}
          studentSearch={studentSearch}
          setStudentSearch={setStudentSearch}
          rosterLoading={rosterLoading}
          busy={busy}
          actionError={actionError}
          message={message}
          close={() => setSelected(null)}
          assign={assign}
        />
      )}
      {createOpen && (
        <CreateClassModal
          form={classForm}
          setForm={setClassForm}
          subjects={modalOptions.subjects}
          slots={modalOptions.slots}
          teachers={teachers}
          busy={busy}
          error={actionError}
          close={() => setCreateOpen(false)}
          save={saveClass}
        />
      )}
    </>
  )
}

function CreateClassModal(props: {
  form: ClassForm
  setForm: (value: ClassForm) => void
  subjects: SubjectRow[]
  slots: SlotRow[]
  teachers: TeacherOption[]
  busy: boolean
  error: string | null
  close: () => void
  save: () => Promise<void>
}) {
  const { form, setForm, subjects, slots, teachers, busy, error, close, save } = props
  return (
    <div className="modal-layer">
      <div className="scrim" onClick={close} />
      <section className="modal create-class-modal">
        <div className="modal-head">
          <div>
            <span className="eyebrow">LỚP HỌC MỚI</span>
            <h2>Thêm và phân công lớp</h2>
            <p>Giảng viên, phòng và slot sẽ được kiểm tra xung đột trước khi lưu.</p>
          </div>
          <Button variant="icon" onClick={close}>
            <X size={20} />
          </Button>
        </div>
        {error && (
          <section className="data-error">
            <b>Chưa thể tạo lớp</b>
            <span>{error}</span>
          </section>
        )}
        <div className="form-grid">
          <Field
            label="Mã lớp *"
            value={form.classCode}
            onChange={(value) => setForm({ ...form, classCode: value })}
            placeholder="VD: PRM392_SE1920"
          />
          <label className="select-wrap field-select">
            <span>Môn học *</span>
            <select
              value={form.subjectCode}
              onChange={(event) => setForm({ ...form, subjectCode: event.target.value })}
            >
              <option value="">Chọn môn học</option>
              {subjects.map((item) => (
                <option key={item.subjectCode} value={item.subjectCode}>
                  {item.subjectCode} · {item.subjectName}
                </option>
              ))}
            </select>
          </label>
          <label className="select-wrap field-select">
            <span>Giảng viên *</span>
            <select
              value={form.teacherMemberCode}
              onChange={(event) => setForm({ ...form, teacherMemberCode: event.target.value })}
            >
              <option value="">Chọn giảng viên</option>
              {teachers.map((item) => (
                <option key={item.id} value={item.memberCode} disabled={item.active === false}>
                  {item.fullName || item.memberCode} · {item.memberCode}
                  {item.active === false ? " (đã khóa)" : ""}
                </option>
              ))}
            </select>
          </label>
          <label className="select-wrap field-select">
            <span>Slot *</span>
            <select
              value={form.slotCode}
              onChange={(event) => setForm({ ...form, slotCode: event.target.value })}
            >
              <option value="">Chọn slot</option>
              {slots.map((item) => (
                <option key={item.slotCode} value={item.slotCode}>
                  {item.slotCode} · {item.startTime}–{item.endTime} · {item.weekdays.map((day) => `T${day}`).join(", ")}
                </option>
              ))}
            </select>
          </label>
          <Field
            label="Phòng học *"
            value={form.room}
            onChange={(value) => setForm({ ...form, room: value })}
            placeholder="VD: 404"
          />
          <Field
            label="Sức chứa *"
            type="number"
            value={form.capacity}
            onChange={(value) => setForm({ ...form, capacity: value })}
          />
        </div>
        <div className="modal-actions">
          <Button variant="secondary" onClick={close}>
            Hủy
          </Button>
          <Button
            icon={busy ? <LoaderCircle className="spin" size={17} /> : <Plus size={17} />}
            disabled={busy}
            onClick={() => void save()}
          >
            Tạo lớp học
          </Button>
        </div>
      </section>
    </div>
  )
}

function ClassDrawer(props: {
  selected: ClassRow
  students: StudentOption[]
  enrollments: EnrollmentRow[]
  candidates: StudentOption[]
  studentId: string
  setStudentId: (id: string) => void
  studentSearch: string
  setStudentSearch: (value: string) => void
  rosterLoading: boolean
  busy: boolean
  actionError: string | null
  message: string | null
  close: () => void
  assign: () => Promise<void>
}) {
  const {
    selected,
    enrollments,
    candidates,
    studentId,
    setStudentId,
    studentSearch,
    setStudentSearch,
    rosterLoading,
    busy,
    actionError,
    message,
    close,
    assign,
  } = props
  return (
    <div className="drawer-layer">
      <div className="scrim" onClick={close} />
      <aside className="drawer academic-drawer">
        <div className="drawer-head">
          <div>
            <span className="eyebrow">QUẢN LÝ LỚP HỌC</span>
            <h2>{selected.classCode}</h2>
            <p>
              {selected.subjectName} · {selected.slotCode || "Chưa có lịch"}
            </p>
          </div>
          <Button variant="icon" onClick={close}>
            <X size={20} />
          </Button>
        </div>
        <div className="drawer-body">
          <div className="class-summary">
            <div>
              <span>Môn học</span>
              <b>
                {selected.subjectCode} · {selected.subjectName}
              </b>
            </div>
            <div>
              <span>Giảng viên</span>
              <b>{selected.teacherName || selected.teacherMemberCode || "Chưa phân công"}</b>
            </div>
            <div>
              <span>Phòng / slot</span>
              <b>
                {selected.room || "—"} / {selected.slotCode || "—"}
              </b>
            </div>
            <div>
              <span>Sĩ số</span>
              <b>{enrollments.length || selected.studentCount}</b>
            </div>
          </div>
          {actionError && (
            <section className="data-error">
              <b>Không thể thêm sinh viên</b>
              <span>{actionError}</span>
            </section>
          )}
          {message && (
            <section className="data-success">
              <b>Thành công</b>
              <span>{message}</span>
            </section>
          )}
          <section className="assign-student">
            <div className="card-head">
              <div>
                <h3>Thêm sinh viên vào lớp</h3>
                <p>Tự kiểm tra trùng lớp, trùng môn, trùng lịch và sức chứa.</p>
              </div>
              <UserPlus size={19} />
            </div>
            <label className="search-box">
              <Search size={17} />
              <input
                value={studentSearch}
                onChange={(event) => setStudentSearch(event.target.value)}
                placeholder="Lọc theo tên, roll number hoặc email..."
              />
            </label>
            <label className="select-wrap field-select">
              <span>Sinh viên</span>
              <select
                value={studentId}
                onChange={(event) => setStudentId(event.target.value)}
                disabled={rosterLoading}
              >
                <option value="">{rosterLoading ? "Đang tải sinh viên..." : "Chọn sinh viên"}</option>
                {candidates.map((student) => (
                  <option key={student.id} value={student.id}>
                    {student.fullName || student.rollNumber} · {student.rollNumber}
                  </option>
                ))}
              </select>
            </label>
            <Button
              icon={busy ? <LoaderCircle className="spin" size={17} /> : <UserPlus size={17} />}
              disabled={busy || rosterLoading || !studentId}
              onClick={() => void assign()}
            >
              Thêm vào lớp
            </Button>
          </section>
          <section className="class-roster">
            <div className="card-head">
              <div>
                <h3>Danh sách sinh viên</h3>
                <p>{enrollments.length} sinh viên đang được ghi danh</p>
              </div>
              <Users size={19} />
            </div>
            {rosterLoading ? (
              <div className="data-loading">
                <LoaderCircle className="spin" size={22} />
              </div>
            ) : enrollments.length ? (
              <RosterList enrollments={enrollments} />
            ) : (
              <div className="mini-empty">Lớp chưa có sinh viên.</div>
            )}
          </section>
        </div>
      </aside>
    </div>
  )
}

function RosterList({ enrollments }: { enrollments: EnrollmentRow[] }) {
  const [page, setPage] = useState(1)
  const paginated = useMemo(() => enrollments.slice((page - 1) * 10, page * 10), [enrollments, page])

  return (
    <div>
      <div className="roster-list">
        {paginated.map((item) => (
          <div key={item.id}>
            <span className="avatar">{initials(item.fullName)}</span>
            <span>
              <b>{item.fullName || item.rollNumber}</b>
              <small>
                {item.rollNumber} · {item.email}
              </small>
            </span>
          </div>
        ))}
      </div>
      <Pagination
        currentPage={page}
        totalItems={enrollments.length}
        pageSize={10}
        onPageChange={setPage}
        itemLabel="sinh viên trong lớp"
      />
    </div>
  )
}

function ClassesTable({ rows, open }: { rows: ClassRow[]; open: (row: ClassRow) => void }) {
  if (!rows.length) return <Empty icon={<GraduationCap size={28} />} label="Chưa có lớp học" />
  return (
    <div className="table-scroll">
      <table className="admin-data-table">
        <thead>
          <tr>
            <th>Mã lớp</th>
            <th>Môn học</th>
            <th>Giảng viên</th>
            <th>Phòng</th>
            <th>Slot</th>
            <th>Sĩ số</th>
            <th className="text-right">Thao tác</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.classCode} onClick={() => open(row)}>
              <td>
                <b className="code-link text-sm">{row.classCode}</b>
              </td>
              <td>
                <b className="text-slate-900 text-sm">{row.subjectName}</b>
                <small className="cell-note">
                  {row.subjectCode} · {row.credits} tín chỉ
                </small>
              </td>
              <td>
                <span className="text-slate-800 font-medium text-sm">
                  {row.teacherName || row.teacherMemberCode || "Chưa phân công"}
                </span>
                <small className="cell-note">{row.teacherName ? row.teacherMemberCode : ""}</small>
              </td>
              <td className="text-slate-700 text-sm">{row.room || "—"}</td>
              <td className="text-slate-700 text-sm">{row.slotCode || "—"}</td>
              <td className="text-slate-900 font-semibold text-sm">{row.studentCount}</td>
              <td className="text-right">
                <Button variant="secondary" icon={<UserPlus size={15} />} onClick={() => open(row)}>
                  Quản lý
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function SubjectsTable({ rows }: { rows: SubjectRow[] }) {
  if (!rows.length) return <Empty icon={<BookOpen size={28} />} label="Chưa có môn học" />
  return (
    <div className="table-scroll">
      <table className="admin-data-table">
        <thead>
          <tr>
            <th>Mã môn</th>
            <th>Tên môn</th>
            <th>Tín chỉ</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.subjectCode}>
              <td>
                <b className="code-link text-sm">{row.subjectCode}</b>
              </td>
              <td className="text-slate-800 font-medium text-sm">{row.subjectName}</td>
              <td className="text-slate-700 text-sm">{row.credits}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function SlotsTable({ rows }: { rows: SlotRow[] }) {
  if (!rows.length) return <Empty icon={<Clock3 size={28} />} label="Chưa có khung giờ" />
  return (
    <div className="table-scroll">
      <table className="admin-data-table">
        <thead>
          <tr>
            <th>Mã slot</th>
            <th>Khung giờ</th>
            <th>Thời gian</th>
            <th>Ngày trong tuần</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.slotCode}>
              <td>
                <b className="code-link text-sm">{row.slotCode}</b>
              </td>
              <td className="text-slate-800 font-medium text-sm">
                {row.timeSlotId} · {row.period}
              </td>
              <td className="text-slate-700 text-sm">
                {row.startTime}–{row.endTime}
              </td>
              <td className="text-slate-700 text-sm">{row.weekdays.map((day) => `T${day}`).join(", ")}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function Empty({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <div className="empty-state compact-empty">
      <span>{icon}</span>
      <h3>{label}</h3>
    </div>
  )
}

function initials(name: string) {
  return (
    name
      .trim()
      .split(/\s+/)
      .slice(-2)
      .map((word) => word[0]?.toUpperCase())
      .join("") || "SV"
  )
}
