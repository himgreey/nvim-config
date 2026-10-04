-- ============================================
-- Unity C# 代码片段 (LuaSnip)
-- 使用 <Tab> 在占位符之间跳转
-- ============================================

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt

-- 返回 snippet 表，按文件类型分组
return {
    -- ===== MonoBehaviour =====
    s(
        "mono",
        fmt(
            [[
using UnityEngine;

public class {} : MonoBehaviour
{{
    // ==== 生命周期 ====
    void Awake()
    {{
        {}
    }}

    void Start()
    {{
        {}
    }}

    void Update()
    {{
        {}
    }}
}}
]],
            {
                i(1, "NewBehaviour"),
                i(2, ""),
                i(3, ""),
                i(4, ""),
            }
        ),
        { desc = "MonoBehaviour class" }
    ),

    -- ===== MonoBehaviour (完整生命周期) =====
    s(
        "monofull",
        fmt(
            [[
using UnityEngine;

public class {} : MonoBehaviour
{{
    void Awake()
    {{
        {}
    }}

    void OnEnable()
    {{
        {}
    }}

    void Start()
    {{
        {}
    }}

    void Update()
    {{
        {}
    }}

    void FixedUpdate()
    {{
        {}
    }}

    void LateUpdate()
    {{
        {}
    }}

    void OnDisable()
    {{
        {}
    }}

    void OnDestroy()
    {{
        {}
    }}
}}
]],
            {
                i(1, "NewBehaviour"),
                i(2, ""),
                i(3, ""),
                i(4, ""),
                i(5, ""),
                i(6, ""),
                i(7, ""),
                i(8, ""),
                i(9, ""),
            }
        ),
        { desc = "MonoBehaviour (full lifecycle)" }
    ),

    -- ===== ScriptableObject =====
    s(
        "scriptable",
        fmt(
            [[
using UnityEngine;

[CreateAssetMenu(fileName = "{}", menuName = "{}/{}", order = 0)]
public class {} : ScriptableObject
{{
    [Header("Settings")]
    {}

    public void Initialize()
    {{
        {}
    }}
}}
]],
            {
                i(1, "NewData"),
                i(2, "Game"),
                i(3, "Data Name"),
                i(4, "NewDataScriptable"),
                i(5, "// public fields here"),
                i(6, ""),
            }
        ),
        { desc = "ScriptableObject class" }
    ),

    -- ===== Editor 脚本 =====
    s(
        "editor",
        fmt(
            [[
#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof({}))]
public class {}Editor : Editor
{{
    public override void OnInspectorGUI()
    {{
        base.OnInspectorGUI();

        {} targetScript = ({})(target);

        {}
    }}
}}
#endif
]],
            {
                i(1, "MyComponent"),
                i(2, "MyComponent"),
                i(3, "MyComponent"),
                i(4, "MyComponent"),
                i(5, "// Custom inspector GUI"),
            }
        ),
        { desc = "Custom Editor script" }
    ),

    -- ===== Custom Property Drawer =====
    s(
        "drawer",
        fmt(
            [[
#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

[CustomPropertyDrawer(typeof({}))]
public class {}Drawer : PropertyDrawer
{{
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {{
        EditorGUI.BeginProperty(position, label, property);

        {}
        EditorGUI.PropertyField(position, property, label);

        EditorGUI.EndProperty();
    }}

    public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
    {{
        return EditorGUI.GetPropertyHeight(property, label);
    }}
}}
#endif
]],
            {
                i(1, "MyType"),
                i(2, "MyType"),
                i(3, ""),
            }
        ),
        { desc = "Custom Property Drawer" }
    ),

    -- ===== SerializeField 属性 =====
    s("sf", t("[SerializeField] private "), { desc = "SerializeField field" }),

    -- ===== Header 属性 =====
    s(
        "hdr",
        fmt(
            [[

    [Header("{}")]
    {}
]],
            {
                i(1, "Settings"),
                i(0, ""),
            }
        ),
        { desc = "Header attribute" }
    ),

    -- ===== Debug.Log =====
    s(
        "dlog",
        fmt([[Debug.Log("{}"{});]], {
            i(1, "message"),
            c(2, {
                t(""),
                t(", this"),
                t(", gameObject"),
            }),
        }),
        { desc = "Debug.Log" }
    ),

    -- ===== Debug.LogWarning =====
    s(
        "dwarn",
        fmt([[Debug.LogWarning("{}"{});]], {
            i(1, "warning"),
            c(2, {
                t(""),
                t(", this"),
            }),
        }),
        { desc = "Debug.LogWarning" }
    ),

    -- ===== Debug.LogError =====
    s(
        "derr",
        fmt([[Debug.LogError("{}"{});]], {
            i(1, "error"),
            c(2, {
                t(""),
                t(", this"),
            }),
        }),
        { desc = "Debug.LogError" }
    ),

    -- ===== GetComponent =====
    s(
        "getcomp",
        fmt(
            [[
{} {} = GetComponent<{}>();
if ({} == null)
{{
    Debug.LogError("{} not found on " + gameObject.name, this);
    return;
}}
{}
]],
            {
                c(1, { t("var"), t("") }),
                i(2, "comp"),
                i(3, "Component"),
                i(4, "comp"),
                i(5, "comp"),
                i(0, ""),
            }
        ),
        { desc = "GetComponent with null check" }
    ),

    -- ===== TryGetComponent =====
    s(
        "tryget",
        fmt(
            [[
if (TryGetComponent<{}>(out var {}))
{{
    {}
}}
]],
            {
                i(1, "Component"),
                i(2, "comp"),
                i(0, ""),
            }
        ),
        { desc = "TryGetComponent" }
    ),

    -- ===== Coroutine =====
    s(
        "coroutine",
        fmt(
            [[
private IEnumerator {}()
{{
    {}
    yield return {};
    {}
}}
]],
            {
                i(1, "MyCoroutine"),
                i(2, ""),
                c(3, {
                    t("null"),
                    t("new WaitForSeconds(0.5f)"),
                    t("new WaitForEndOfFrame()"),
                    t("new WaitForFixedUpdate()"),
                }),
                i(0, ""),
            }
        ),
        { desc = "Coroutine method" }
    ),

    -- ===== StartCoroutine =====
    s(
        "startcor",
        fmt([[StartCoroutine({}());]], {
            i(1, "MyCoroutine"),
        }),
        { desc = "StartCoroutine call" }
    ),

    -- ===== UnityEvent =====
    s(
        "uevent",
        fmt(
            [[
[SerializeField] private UnityEvent<{}> {} = new();
]],
            {
                i(1, "string"),
                i(2, "onEvent"),
            }
        ),
        { desc = "UnityEvent field" }
    ),

    -- ===== RequireComponent =====
    s(
        "require",
        fmt(
            [[
[RequireComponent(typeof({}))]
]],
            {
                i(1, "Rigidbody"),
            }
        ),
        { desc = "RequireComponent attribute" }
    ),

    -- ===== Namespace 包裹 =====
    s(
        "ns",
        fmt(
            [[
namespace {}
{{
    {}
}}
]],
            {
                i(1, "MyNamespace"),
                i(0, ""),
            }
        ),
        { desc = "Namespace block" }
    ),

    -- ===== #region =====
    s(
        "region",
        fmt(
            [[
#region {}
{}
#endregion
]],
            {
                i(1, "Region"),
                i(0, ""),
            }
        ),
        { desc = "#region block" }
    ),

    -- ===== Singleton (MonoBehaviour) =====
    s(
        "singleton",
        fmt(
            [[
using UnityEngine;

public class {} : MonoBehaviour
{{
    private static {} _instance;
    public static {} Instance
    {{
        get
        {{
            if (_instance == null)
            {{
                _instance = FindAnyObjectByType<{}>();
                if (_instance == null)
                {{
                    var obj = new GameObject("{}");
                    _instance = obj.AddComponent<{}>();
                    DontDestroyOnLoad(obj);
                }}
            }}
            return _instance;
        }}
    }}

    void Awake()
    {{
        if (_instance != null && _instance != this)
        {{
            Destroy(gameObject);
            return;
        }}
        _instance = this;
        DontDestroyOnLoad(gameObject);
    }}
}}
]],
            {
                i(1, "GameManager"),
                i(2, "GameManager"),
                i(3, "GameManager"),
                i(4, "GameManager"),
                i(5, "GameManager"),
                i(6, "GameManager"),
            }
        ),
        { desc = "Singleton MonoBehaviour" }
    ),

    -- ===== OnTrigger/OnCollision 常用回调 =====
    s(
        "ontrigger",
        fmt(
            [[
void OnTriggerEnter(Collider other)
{{
    if (other.CompareTag("{}"))
    {{
        {}
    }}
}}

void OnTriggerExit(Collider other)
{{
    if (other.CompareTag("{}"))
    {{
        {}
    }}
}}
]],
            {
                i(1, "Player"),
                i(2, ""),
                i(3, "Player"),
                i(4, ""),
            }
        ),
        { desc = "OnTrigger callbacks" }
    ),

    s(
        "oncollision",
        fmt(
            [[
void OnCollisionEnter(Collision collision)
{{
    if (collision.gameObject.CompareTag("{}"))
    {{
        {}
    }}
}}
]],
            {
                i(1, "Player"),
                i(2, ""),
            }
        ),
        { desc = "OnCollisionEnter callback" }
    ),

    -- ===== Transform shortcuts =====
    s("tfm", t("transform."), { desc = "transform." }),
    s("go", t("gameObject."), { desc = "gameObject." }),
}
