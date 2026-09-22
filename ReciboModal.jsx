import React from "react";
import Logo from "../assets/Logo.png";

function ReciboModal({ recibo, detalles = [], onClose }) {
  if (!recibo) return null;

  const numRecibo = recibo.Numero_Recibo || `RC-${String(recibo.idFacturas || recibo.id || 1).padStart(4, "0")}`;
  const fechaStr = recibo.Fecha ? new Date(recibo.Fecha).toLocaleDateString("es-CO", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit"
  }) : new Date().toLocaleDateString("es-CO");

  const clienteNombre = recibo.clienteNombre || 
    (recibo.Nombres ? `${recibo.Nombres} ${recibo.Apellidos || ""}`.trim() : recibo.cliente || "Cliente Tecnomatic");

  const esPagado = (recibo.Estado || "Pagado").toLowerCase() === "pagado" || 
                   (recibo.Estado || "Pagado").toLowerCase() === "compra realizada";

  const totalNum = Number(recibo.Total || 0);

  const imprimir = () => {
    window.print();
  };

  return (
    <div 
      className="modal fade show d-block" 
      tabIndex="-1" 
      style={{ backgroundColor: "rgba(0, 20, 50, 0.75)", zIndex: 1060 }}
    >
      <div className="modal-dialog modal-dialog-centered modal-lg">
        <div className="modal-content border-0 shadow-lg" style={{ borderRadius: "20px", overflow: "hidden" }}>
          
          {/* BARRA SUPERIOR ACCIONES */}
          <div 
            className="d-flex justify-content-between align-items-center px-4 py-3 text-white"
            style={{ background: "linear-gradient(90deg, #002B73 0%, #0047AB 100%)" }}
          >
            <div className="d-flex align-items-center gap-2">
              <i className="bi bi-receipt-cutoff text-warning fs-5"></i>
              <span className="fw-bold" style={{ letterSpacing: "0.5px" }}>RECIBO DE COMPRA OFICIAL</span>
            </div>
            <div className="d-flex align-items-center gap-2">
              <button 
                onClick={imprimir} 
                className="btn btn-sm btn-light text-primary fw-bold d-flex align-items-center gap-1.5 px-3 py-1.5"
                style={{ borderRadius: "10px" }}
              >
                <i className="bi bi-printer-fill"></i> Imprimir
              </button>
              <button 
                type="button" 
                className="btn-close btn-close-white" 
                onClick={onClose}
                aria-label="Close"
              ></button>
            </div>
          </div>

          {/* CUERPO DEL RECIBO */}
          <div className="modal-body p-4 p-md-5 bg-white print-container">
            
            {/* ENCABEZADO CORPORATIVO */}
            <div className="row align-items-center pb-4 border-bottom mb-4">
              <div className="col-md-7 d-flex align-items-center gap-3">
                <img 
                  src={Logo} 
                  alt="Tecnomatic MAV" 
                  style={{ width: "65px", height: "65px", objectFit: "cover", borderRadius: "12px" }}
                />
                <div>
                  <h4 className="fw-extrabold mb-0" style={{ color: "#0047AB", letterSpacing: "0.5px" }}>
                    TECNOMATIC <span style={{ color: "#20B2AA" }}>MAV</span>
                  </h4>
                  <p className="text-muted small mb-0 fw-medium">Dotaciones y Equipos de Seguridad Industrial</p>
                  <p className="text-muted small mb-0" style={{ fontSize: "11px" }}>NIT: 901.458.823-1 • Bogotá, Colombia</p>
                </div>
              </div>

              <div className="col-md-5 text-md-end mt-3 mt-md-0">
                <div 
                  className="d-inline-block p-2 px-3 rounded-3 text-start"
                  style={{ backgroundColor: "#F0F7FF", border: "1px solid #BFDBFE" }}
                >
                  <div className="text-muted small fw-bold" style={{ fontSize: "11px" }}>N° DE RECIBO</div>
                  <div className="fs-5 fw-extrabold" style={{ color: "#0047AB" }}>{numRecibo}</div>
                </div>
                <div className="mt-2">
                  <span 
                    className={`badge px-3 py-1.5 rounded-pill ${esPagado ? "bg-success" : "bg-warning text-dark"}`}
                    style={{ fontSize: "12px", fontWeight: "700" }}
                  >
                    <i className={`bi ${esPagado ? "bi-check-circle-fill" : "bi-clock-history"} me-1`}></i>
                    {esPagado ? "PAGADO" : (recibo.Estado || "PENDIENTE").toUpperCase()}
                  </span>
                </div>
              </div>
            </div>

            {/* DATOS DEL COMPRADOR Y EMISIÓN */}
            <div className="p-3 mb-4 rounded-4" style={{ backgroundColor: "#F8FAFC", border: "1px solid #E2E8F0" }}>
              <div className="row g-3" style={{ fontSize: "13.5px" }}>
                <div className="col-sm-6">
                  <span className="text-muted d-block small">Cliente:</span>
                  <strong className="text-dark fs-6">{clienteNombre}</strong>
                  {recibo.Cedula && (
                    <div className="text-muted small mt-0.5">
                      <i className="bi bi-card-heading me-1"></i> CC: {recibo.Cedula}
                    </div>
                  )}
                </div>
                <div className="col-sm-6 text-sm-end">
                  <span className="text-muted d-block small">Fecha y Hora:</span>
                  <strong className="text-dark">{fechaStr}</strong>
                  {recibo.Correo && (
                    <div className="text-muted small mt-0.5">
                      <i className="bi bi-envelope me-1"></i> {recibo.Correo}
                    </div>
                  )}
                  {recibo.Telefono && (
                    <div className="text-muted small">
                      <i className="bi bi-telephone me-1"></i> {recibo.Telefono}
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* TABLA DE PRODUCTOS COMPRADOS */}
            <h6 className="fw-bold mb-3" style={{ color: "#0047AB" }}>
              <i className="bi bi-box-seam me-1.5"></i> Artículos del Recibo
            </h6>

            <div className="table-responsive mb-4">
              <table className="table align-middle">
                <thead style={{ backgroundColor: "#0047AB", color: "#ffffff" }}>
                  <tr>
                    <th className="py-2.5 px-3 border-0 rounded-start" style={{ fontSize: "12px" }}>CONCEPTO / PRODUCTO</th>
                    <th className="py-2.5 px-3 border-0 text-center" style={{ fontSize: "12px" }}>CANTIDAD</th>
                    <th className="py-2.5 px-3 border-0 text-end" style={{ fontSize: "12px" }}>PRECIO UNIT.</th>
                    <th className="py-2.5 px-3 border-0 text-end rounded-end" style={{ fontSize: "12px" }}>SUBTOTAL</th>
                  </tr>
                </thead>
                <tbody>
                  {detalles && detalles.length > 0 ? (
                    detalles.map((d, i) => {
                      const cant = Number(d.Cantidad || d.cantidad || 1);
                      const pu = Number(d.Precio_Unitario || d.precioUnitario || d.precio || 0);
                      const sub = Number(d.Subtotal || cant * pu);
                      const prodName = d.Nombre_Producto || d.nombre || d.nombreProducto || "Producto";

                      return (
                        <tr key={i} style={{ borderBottom: "1px solid #EDF2F7" }}>
                          <td className="py-2.5 px-3 fw-semibold text-dark">{prodName}</td>
                          <td className="py-2.5 px-3 text-center">{cant}</td>
                          <td className="py-2.5 px-3 text-end text-muted">${pu.toLocaleString("es-CO")}</td>
                          <td className="py-2.5 px-3 text-end fw-bold" style={{ color: "#0047AB" }}>
                            ${sub.toLocaleString("es-CO")}
                          </td>
                        </tr>
                      );
                    })
                  ) : (
                    <tr>
                      <td colSpan="4" className="py-3 text-center text-muted small">
                        Compra registrada por valor global de ${totalNum.toLocaleString("es-CO")}
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* RESUMEN FINANCIERO */}
            <div className="row justify-content-end mb-4">
              <div className="col-md-6 col-lg-5">
                <div className="p-3 rounded-3" style={{ backgroundColor: "#F1F5F9" }}>
                  <div className="d-flex justify-content-between mb-1.5" style={{ fontSize: "13px" }}>
                    <span className="text-muted">Subtotal:</span>
                    <span className="fw-semibold text-dark">${totalNum.toLocaleString("es-CO")}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-2 pb-2 border-bottom" style={{ fontSize: "13px" }}>
                    <span className="text-muted">Envío / Despacho:</span>
                    <span className="text-success fw-bold">Gratis</span>
                  </div>
                  <div className="d-flex justify-content-between align-items-center">
                    <span className="fw-bold text-dark fs-6">TOTAL RECIBO:</span>
                    <span className="fw-extrabold fs-5" style={{ color: "#0047AB" }}>
                      ${totalNum.toLocaleString("es-CO")}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* NOTA INSTITUCIONAL CONTABLE */}
            <div 
              className="p-3 rounded-3 text-center" 
              style={{ backgroundColor: "#F8FAFC", border: "1px dashed #CBD5E1", fontSize: "11.5px", color: "#64748B" }}
            >
              <i className="bi bi-info-circle me-1 text-primary"></i>
              <strong>Aviso Oficial:</strong> Este documento certifica formalmente la compra efectuada en Tecnomatic MAV.
              No constituye factura fiscal y ha sido radicado para control contable y auditoría interna.
            </div>

          </div>

          {/* FOOTER */}
          <div className="modal-footer bg-light border-top-0 px-4 py-3">
            <button 
              type="button" 
              className="btn btn-secondary px-4 fw-semibold" 
              style={{ borderRadius: "10px" }}
              onClick={onClose}
            >
              Cerrar
            </button>
            <button 
              type="button" 
              className="btn text-white fw-bold px-4 d-flex align-items-center gap-1.5" 
              style={{ background: "#20B2AA", borderRadius: "10px" }}
              onClick={imprimir}
            >
              <i className="bi bi-printer"></i> Imprimir Recibo
            </button>
          </div>

        </div>
      </div>
    </div>
  );
}

export default ReciboModal;
