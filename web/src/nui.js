// NUI bridge utility
// Detects if running inside FiveM or in browser (dev mode)

const IS_FIVEM = window.invokeNative !== undefined || navigator.userAgent.includes('FiveM')

export async function fetchNUI(event, data = {}) {
  if (!IS_FIVEM) {
    // Dev mode: mock responses
    return mockResponse(event, data)
  }

  const resp = await fetch(`https://${window.GetParentResourceName?.() ?? 'jobclothing'}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
  return resp.json()
}

// ── Dev mode mocks ──────────────────────────────────────────
const MOCK_PEDS = [
  { id: 1, model: 's_m_y_cop_01', label: 'Police Station', x: 447.0, y: -981.0, z: 30.0, heading: 90.0 },
  { id: 2, model: 'a_m_m_skater_01', label: 'Taxi Stand', x: 900.0, y: -185.0, z: 74.0, heading: 180.0 },
]

const MOCK_JOBS = [
  {
    name: 'police', label: 'Police',
    grades: [
      { grade: 0, name: 'Recruit', label: 'Recruit' },
      { grade: 1, name: 'Officer', label: 'Officer' },
      { grade: 2, name: 'Sergeant', label: 'Sergeant' },
      { grade: 3, name: 'Lieutenant', label: 'Lieutenant' },
    ],
  },
  {
    name: 'ambulance', label: 'Ambulance',
    grades: [
      { grade: 0, name: 'Cadet', label: 'Cadet' },
      { grade: 1, name: 'EMT', label: 'EMT' },
      { grade: 2, name: 'Paramedic', label: 'Paramedic' },
    ],
  },
  {
    name: 'mechanic', label: 'Mechanic',
    grades: [
      { grade: 0, name: 'Apprentice', label: 'Apprentice' },
      { grade: 1, name: 'Mechanic', label: 'Mechanic' },
    ],
  },
]

const MOCK_UNIFORMS = {
  1: [
    {
      id: 1, ped_id: 1, job_name: 'police', job_grade: 1,
      uniform_name: 'Patrol',
      outfit_data: { components: { jacket: { drawable: 55, texture: 0, palette: 0 } }, props: {} },
    },
    {
      id: 2, ped_id: 1, job_name: 'police', job_grade: 2,
      uniform_name: 'Tactical',
      outfit_data: { components: { jacket: { drawable: 30, texture: 0, palette: 0 } }, props: {} },
    },
  ],
}

async function mockResponse(event, data) {
  await new Promise(r => setTimeout(r, 200))
  switch (event) {
    case 'getPeds':        return MOCK_PEDS
    case 'getJobs':        return MOCK_JOBS
    case 'getGrades':      return MOCK_JOBS.find(j => j.name === data.job)?.grades ?? []
    case 'getUniformsForPed': return MOCK_UNIFORMS[data.pedId] ?? []
    case 'createPed':      return { id: Date.now(), ...data }
    case 'deletePed':      return { success: true }
    case 'createUniform':  return { id: Date.now(), ...data }
    case 'updateUniform':  return { success: true }
    case 'deleteUniform':  return { success: true }
    case 'getSystemInfo':  return { clothing: 'illenium-appearance', components: { components: ['jacket', 'pants', 'shoes'], props: ['hat', 'glasses'] } }
    case 'openClothingEditor': return { success: true, outfitData: { components: { jacket: { drawable: 12, texture: 0, palette: 0 } }, props: {} } }
    case 'previewUniform': return {}
    case 'restoreClothing': return {}
    case 'applyUniform':   return {}
    case 'teleportToPed':  return {}
    default:               return {}
  }
}
