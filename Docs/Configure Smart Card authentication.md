To configure **Smart Card authentication** (such as CAC, PIV, or YubiKey tokens) in **Keycloak**, you must set up **X.509/Mutual TLS (mTLS) authentication**. This process establishes trust with your card’s Certificate Authority (CA) and extracts the identity mapping directly from the card's certificate. [[1](https://groups.google.com/g/keycloak-user/c/AC4-PH2rqqI), [2](https://www.google.com/goto?url=CAESpQEB6zswFbV7H5M5pWIG050Nwpgb3fL_LO7UjdPjppX8F3LlGan1psYaMxub7KuDBphPB2JcxdPFn20hfTFqZeCN_GUvJzLvybr96C_1YvM72OyxAAnch8sLIVvL_OtpLagKF7cedvGxJVSQaqtTgMyUaKkbhUBtJw_Rnre3GiP2svpJId-SwhxZwWIcJWjS7L3k7_8SOEvli2XiYICkZIW3CpQh0F4), [3](https://www.google.com/goto?url=CAESvwEB6zswFbXMP8gFOcsdiAXgUKu2IQ3o0QK6F7RxeAEsPU5nmvVdoLhif1843jBjJcYBlnNILHZVbzmcwZeNmmb2ZJcFjMWc-IlNzrwSTPtDdvENOLDEHYMi2UFYdHtzlbnUPUXqoQZxu1aARPXBbFyYQ4dFXxdl6bSEJnZGVCElmlWu-XsZ3j8Ll8bv84tWX9uHIM231o4l-Kd2Vd3yv7Guwkh9zRtdipDIbuse23QVDgdHfcssZqdlC9x8CVtrNw), [4](https://www.google.com/goto?url=CAESjgEB6zswFQ5uv1_cEGM-Hrmt1XQ80e_3F2uwHpw5Cy24ldkSm4Z4Xk0CoTZIOMZRNffiYh5JwuU0UOSDYdm3gFtaeCxj1sjOo2kNo5o1jyr6uNMipbLSHMeCjC2b77iokJ0D7JijdEghg5qpV4JL5PaIft1FSnCVlZKSEGdSbTvGbWwtPKVBlkF3maUHEmYt)]

The configuration requires three key phases:

---

**Phase 1: Set up the Truststore & Enable mTLS**

Keycloak needs to request the certificate from the user's browser and trust the CA that issued the smart card. [[1](https://www.google.com/goto?url=CAESkQEB6zswFVCzRCefNIXb6c1tNu4ki14-_qStAwDJH3DaECVDtsjGdw3ZZbztfFu8bV-NVbxeQaGYLfqIgB86-vXQJilLzIocp_65CnRdto3AzWVqukazpXnHMEZgj4sXhiSb1JReL84ezoJCly6cF6ArkzVVDzpVzYgll3sVjGRHAj33_Vs6d_IImCSikPaTN1Xn), [2](https://www.google.com/goto?url=CAESYgHrOzAVzOr5mYXiX2oO_hu7ESZFt777M2MjQThMW_p6sAAtWTcOEBUITi3d65WPyFK_XYuHnUOrtNikcA6QM6ED5__3sE-BazRdx-AxA7UqRQk8q20Z4zwkP1_kf61gGsgl)]

- **Create a Truststore:** Use `keytool` to import your Root and Intermediate CA certificates (e.g., DoD CA chains or your company’s PKI) into a Java keystore (`.p12` or `.jks`). [[1](https://www.google.com/goto?url=CAESkQEB6zswFVCzRCefNIXb6c1tNu4ki14-_qStAwDJH3DaECVDtsjGdw3ZZbztfFu8bV-NVbxeQaGYLfqIgB86-vXQJilLzIocp_65CnRdto3AzWVqukazpXnHMEZgj4sXhiSb1JReL84ezoJCly6cF6ArkzVVDzpVzYgll3sVjGRHAj33_Vs6d_IImCSikPaTN1Xn), [2](https://groups.google.com/g/keycloak-user/c/AC4-PH2rqqI)]

- **Configure Keycloak Server (`keycloak.conf`):** Add or update the following properties to force Keycloak to request certificates during the TLS handshake:
  
  properties
  
  ```
  # Enable client certificate 
  requesthttps-client-auth=request
  
  # Define the truststore path and password containing the smart card issuing CAs
  https-trust-store-file=/path/to/your/truststore.p12
  https-trust-store-password=your_secure_password
  ```
  
  *(Note: If Keycloak runs behind a reverse proxy like Nginx or an AWS ALB, you must configure the proxy to handle the mTLS handshake instead and forward the certificate via HTTP headers to Keycloak).* [[1](https://www.google.com/goto?url=CAESpAEB6zswFX8QF8YMCn_QYx2ax6s49xehqvjMxu2KZDBUvzv5dFxG5cktyOslrmc-GTJo6DVjjABYo_srcskcKPMj5V8hgSSdEpww3ae44L5i-2kNFAI_58WuBsGAR217pUFwJENKrKf5Lw967PDK2twl2YTcObHcR9NrKh5QzCigycKDB9_yDZpiktGOJGWa0LwGV2MIJrtZ3mY0GWEXbABPRHytgQ), [2](https://www.google.com/goto?url=CAESYgHrOzAVzOr5mYXiX2oO_hu7ESZFt777M2MjQThMW_p6sAAtWTcOEBUITi3d65WPyFK_XYuHnUOrtNikcA6QM6ED5__3sE-BazRdx-AxA7UqRQk8q20Z4zwkP1_kf61gGsgl), [3](https://www.google.com/goto?url=CAESjgEB6zswFQ5uv1_cEGM-Hrmt1XQ80e_3F2uwHpw5Cy24ldkSm4Z4Xk0CoTZIOMZRNffiYh5JwuU0UOSDYdm3gFtaeCxj1sjOo2kNo5o1jyr6uNMipbLSHMeCjC2b77iokJ0D7JijdEghg5qpV4JL5PaIft1FSnCVlZKSEGdSbTvGbWwtPKVBlkF3maUHEmYt)]

---

**Phase 2: Create a Custom Authentication Flow**

You must alter Keycloak's default browser login flow to handle X.509 smart cards. [[1](https://www.google.com/goto?url=CAESpQEB6zswFbV7H5M5pWIG050Nwpgb3fL_LO7UjdPjppX8F3LlGan1psYaMxub7KuDBphPB2JcxdPFn20hfTFqZeCN_GUvJzLvybr96C_1YvM72OyxAAnch8sLIVvL_OtpLagKF7cedvGxJVSQaqtTgMyUaKkbhUBtJw_Rnre3GiP2svpJId-SwhxZwWIcJWjS7L3k7_8SOEvli2XiYICkZIW3CpQh0F4), [2](https://www.google.com/goto?url=CAESpwEB6zswFW8auamrhwJPl2Cv412kB7FU36-bPCw-Laie-kOXuPJXX2OVRumXDhmeH9taec6gKCxisxffZY09-NopvNMmeK67HlnRB1LdvivJyZhCoK1HVrd5tFoH7JV5farC474huU3chl9am_CXxx4gF_L9oAZXsX9Sqah7v_kGWcJXIxgzR1BXkjPwLFpAHc48Fl5Xi_mPY56KTvhEz4x_jsX6McdRMQ)]

- Log in to the **Keycloak Admin Console**.

- Select your target **Realm**.

- Navigate to **Authentication** > **Flows**. [[1](https://www.google.com/goto?url=CAESggEB6zswFeAG49nF3218jiTFTGNAoBDKe0QikgIgM7kMmLyNkLVErWP8iiHg6tbrMEOsyK-oUewoYQZsnpevnmb2gtHmomvEqHLeyCG_Es-EyPAgMXKWFcqh3xBE8y04ZzoIFr_tOQ7otg0Xdttp9rRuHCePr6f7HFfjQdLefN9D1n1_)]

- Locate the built-in **`browser`** flow, click the three vertical dots (Actions), and select **Duplicate**. Name it something like `browser-smartcard`. [[1](https://www.google.com/goto?url=CAESggEB6zswFeAG49nF3218jiTFTGNAoBDKe0QikgIgM7kMmLyNkLVErWP8iiHg6tbrMEOsyK-oUewoYQZsnpevnmb2gtHmomvEqHLeyCG_Es-EyPAgMXKWFcqh3xBE8y04ZzoIFr_tOQ7otg0Xdttp9rRuHCePr6f7HFfjQdLefN9D1n1_)]

- Inside your new flow, click **Add step** or **Add sub-flow** to include the **`X509/Validate Username Form`** authenticator. [[1](https://www.google.com/goto?url=CAESjgEB6zswFcQKU8a2804U9zw4CMMaj64vLMGlLmSLSMaXvaFL1fhJTskxNeRsUkf4KUId6Bg7ho9h4_m_hTFT8dbGG4tE-rILbbx0dtRF0tR9tl3R_LbShfABi5BuZMWJyDMiNx65Yg0MXerGBw-PrJAf5VKBU30qgRS04PBDzkBapq9RqVacWYXFpt-rjWCd)]

- Adjust the requirement requirements according to your policy:
  
  - Set it to **Alternative** if you want to allow users to use *either* a smart card or standard username/password.
  - Set it to **Required** if users *must* log in using a smart card. [[1](https://www.google.com/goto?url=CAESjgEB6zswFcQKU8a2804U9zw4CMMaj64vLMGlLmSLSMaXvaFL1fhJTskxNeRsUkf4KUId6Bg7ho9h4_m_hTFT8dbGG4tE-rILbbx0dtRF0tR9tl3R_LbShfABi5BuZMWJyDMiNx65Yg0MXerGBw-PrJAf5VKBU30qgRS04PBDzkBapq9RqVacWYXFpt-rjWCd)]

- Save and bind the flow by going to the top right **Actions** dropdown of the flow and choosing **Bind flow** > **Browser flow**. [[1](https://www.google.com/goto?url=CAESggEB6zswFeAG49nF3218jiTFTGNAoBDKe0QikgIgM7kMmLyNkLVErWP8iiHg6tbrMEOsyK-oUewoYQZsnpevnmb2gtHmomvEqHLeyCG_Es-EyPAgMXKWFcqh3xBE8y04ZzoIFr_tOQ7otg0Xdttp9rRuHCePr6f7HFfjQdLefN9D1n1_)]

---

**Phase 3: Map the Smart Card Certificate to Users**

Keycloak must know how to pull the user's unique identifier from the certificate's metadata. [[1](https://groups.google.com/g/keycloak-user/c/AC4-PH2rqqI), [2](https://www.google.com/goto?url=CAESjgEB6zswFcQKU8a2804U9zw4CMMaj64vLMGlLmSLSMaXvaFL1fhJTskxNeRsUkf4KUId6Bg7ho9h4_m_hTFT8dbGG4tE-rILbbx0dtRF0tR9tl3R_LbShfABi5BuZMWJyDMiNx65Yg0MXerGBw-PrJAf5VKBU30qgRS04PBDzkBapq9RqVacWYXFpt-rjWCd)]

- In your new authentication flow, click the **Settings cog (Gear icon)** next to the `X509/Validate Username Form` step. [[1](https://www.google.com/goto?url=CAESjgEB6zswFcQKU8a2804U9zw4CMMaj64vLMGlLmSLSMaXvaFL1fhJTskxNeRsUkf4KUId6Bg7ho9h4_m_hTFT8dbGG4tE-rILbbx0dtRF0tR9tl3R_LbShfABi5BuZMWJyDMiNx65Yg0MXerGBw-PrJAf5VKBU30qgRS04PBDzkBapq9RqVacWYXFpt-rjWCd)]

- Configure the following critical parameters:
  
  - **User Identity Source:** Choose where the user ID resides on the card. Common choices are:
    - `Subject's Common Name` (CN)
    - `Subject's Alternative Name E-mail` (RFC822Name—standard for many corporate email profiles)
    - `Subject's Alternative Name Principal Name` (UPN—standard for Microsoft/Active Directory environments)
  - **User Mapping Method:** Select **Username** or **Email** depending on what field you pulled above. This tells Keycloak which database field to check against the token data.
  - **Check certificate validity:** Turn this **ON** to ensure Keycloak validates the certificate dates. [[1](https://groups.google.com/g/keycloak-user/c/AC4-PH2rqqI), [2](https://www.google.com/goto?url=CAESjgEB6zswFcQKU8a2804U9zw4CMMaj64vLMGlLmSLSMaXvaFL1fhJTskxNeRsUkf4KUId6Bg7ho9h4_m_hTFT8dbGG4tE-rILbbx0dtRF0tR9tl3R_LbShfABi5BuZMWJyDMiNx65Yg0MXerGBw-PrJAf5VKBU30qgRS04PBDzkBapq9RqVacWYXFpt-rjWCd), [3](https://www.google.com/goto?url=CAEScQHrOzAVUZMWwpf8Y-2QoRAo_RtIynXNR0FZPYabkGzqkD9UxObO3qsEIWYv-qQxs5pDXnURoR_kqAOkS_nJlG6QFT9UL55eGAkBYm3bHd5va6Y1KVvCc9HQYjSDZs5VwmkUs0MK4oh_jrHAdwuuSw9S)]

- Click **Save**. [[1](https://www.google.com/goto?url=CAESjgEB6zswFcQKU8a2804U9zw4CMMaj64vLMGlLmSLSMaXvaFL1fhJTskxNeRsUkf4KUId6Bg7ho9h4_m_hTFT8dbGG4tE-rILbbx0dtRF0tR9tl3R_LbShfABi5BuZMWJyDMiNx65Yg0MXerGBw-PrJAf5VKBU30qgRS04PBDzkBapq9RqVacWYXFpt-rjWCd)]

---

💡 Tips for Testing & Browsers

- **Middleware:** Ensure users have smart card middleware installed locally (like OpenSC or ActivClient) so their operating system and browser can communicate with the hardware token. [[1](https://www.google.com/goto?url=CAESpQEB6zswFbV7H5M5pWIG050Nwpgb3fL_LO7UjdPjppX8F3LlGan1psYaMxub7KuDBphPB2JcxdPFn20hfTFqZeCN_GUvJzLvybr96C_1YvM72OyxAAnch8sLIVvL_OtpLagKF7cedvGxJVSQaqtTgMyUaKkbhUBtJw_Rnre3GiP2svpJId-SwhxZwWIcJWjS7L3k7_8SOEvli2XiYICkZIW3CpQh0F4)]

- **Clear Sessions:** Browsers cache certificate choices natively. When testing, you will frequently need to completely close your browser or open a fresh Guest/Incognito window to trigger the smart card PIN prompt again. [[1](https://www.google.com/goto?url=CAESggEB6zswFeBZUz-Im6zcIxAdJgDcT5J6Nik2LbV8A_HFUtDmKN79YxV-WlRArgySz9lbG9E43WqH_kbNcgq7kfbxaW83NIJGYsoh7_cSOWrnoEXWqtKqWUx6hXUElfP3vx4RbG0MEhYT4iMQ7T9J188T0hm6KikvWU68mY8lszsDxPno)]
