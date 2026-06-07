"""
Android Studio Loyiha Tahlilchisi - Grafik interfeys (GUI) moduli
"""
import os
import sys
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext


class AndroidExtractorGUI:
    """Android Extractor grafik interfeysi"""

    def __init__(self, extractor):
        self.extractor = extractor
        self.root = tk.Tk()
        self.root.title("Android Studio Loyiha Tahlilchisi")
        self.root.geometry("900x700")
        self.root.configure(bg='#f5f7fa')

        # Asosiy oynani yaratish
        self._create_widgets()

        # Progress o'zgaruvchilari
        self.progress_var = tk.DoubleVar()
        self.status_var = tk.StringVar(value="Tayyor")

    def _create_widgets(self):
        """Widgetlarni yaratish"""
        # Asosiy frame
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Sarlavha
        title_label = ttk.Label(
            main_frame, 
            text="📱 Android Studio Loyiha Tahlilchisi",
            font=('Helvetica', 18, 'bold')
        )
        title_label.pack(pady=(0, 20))

        # Manba tanlash
        source_frame = ttk.LabelFrame(main_frame, text="Manba", padding="10")
        source_frame.pack(fill=tk.X, pady=(0, 10))

        self.source_path = tk.StringVar()
        source_entry = ttk.Entry(source_frame, textvariable=self.source_path, width=60)
        source_entry.pack(side=tk.LEFT, padx=(0, 10), fill=tk.X, expand=True)

        browse_btn = ttk.Button(source_frame, text="Ko'rib chiqish", command=self._browse_source)
        browse_btn.pack(side=tk.LEFT, padx=(0, 5))

        detect_btn = ttk.Button(source_frame, text="JSON topish", command=self._detect_json)
        detect_btn.pack(side=tk.LEFT)

        # Filtr sozlamalari
        filter_frame = ttk.LabelFrame(main_frame, text="Filtrlar", padding="10")
        filter_frame.pack(fill=tk.X, pady=(0, 10))

        # Kengaytmalar
        ext_frame = ttk.Frame(filter_frame)
        ext_frame.pack(fill=tk.X, pady=(0, 5))
        ttk.Label(ext_frame, text="Kengaytmalar:").pack(side=tk.LEFT)
        self.extensions_var = tk.StringVar(value=".java, .kt, .xml, .gradle")
        ext_entry = ttk.Entry(ext_frame, textvariable=self.extensions_var, width=50)
        ext_entry.pack(side=tk.LEFT, padx=(10, 0), fill=tk.X, expand=True)

        # Papka filtri
        folder_frame = ttk.Frame(filter_frame)
        folder_frame.pack(fill=tk.X, pady=(0, 5))
        ttk.Label(folder_frame, text="Papka:").pack(side=tk.LEFT)
        self.folder_var = tk.StringVar()
        folder_entry = ttk.Entry(folder_frame, textvariable=self.folder_var, width=50)
        folder_entry.pack(side=tk.LEFT, padx=(10, 0), fill=tk.X, expand=True)

        # Chiqish formatlari
        format_frame = ttk.LabelFrame(main_frame, text="Chiqish formatlari", padding="10")
        format_frame.pack(fill=tk.X, pady=(0, 10))

        self.format_vars = {}
        formats = ['txt', 'csv', 'json', 'html', 'md']
        for i, fmt in enumerate(formats):
            var = tk.BooleanVar(value=(fmt in ['txt', 'json', 'html']))
            self.format_vars[fmt] = var
            cb = ttk.Checkbutton(format_frame, text=fmt.upper(), variable=var)
            cb.pack(side=tk.LEFT, padx=(0, 15))

        # Tahlil opsiyalari
        options_frame = ttk.LabelFrame(main_frame, text="Tahlil opsiyalari", padding="10")
        options_frame.pack(fill=tk.X, pady=(0, 10))

        self.stats_only_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(options_frame, text="Faqat statistika", variable=self.stats_only_var).pack(side=tk.LEFT, padx=(0, 15))

        self.modules_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Modul tahlili", variable=self.modules_var).pack(side=tk.LEFT, padx=(0, 15))

        self.manifest_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Manifest", variable=self.manifest_var).pack(side=tk.LEFT, padx=(0, 15))

        self.gradle_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Gradle", variable=self.gradle_var).pack(side=tk.LEFT, padx=(0, 15))

        self.resources_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Resurslar", variable=self.resources_var).pack(side=tk.LEFT, padx=(0, 15))

        self.parallel_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Parallel", variable=self.parallel_var).pack(side=tk.LEFT)

        # Progress bar
        progress_frame = ttk.Frame(main_frame)
        progress_frame.pack(fill=tk.X, pady=(0, 10))

        self.progress_bar = ttk.Progressbar(
            progress_frame, 
            variable=self.progress_var, 
            maximum=100,
            mode='determinate',
            length=400
        )
        self.progress_bar.pack(fill=tk.X)

        self.status_label = ttk.Label(progress_frame, textvariable=self.status_var)
        self.status_label.pack(pady=(5, 0))

        # Tugmalar
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(fill=tk.X, pady=(0, 10))

        self.run_btn = ttk.Button(btn_frame, text="Ishga tushirish", command=self._run_analysis)
        self.run_btn.pack(side=tk.LEFT, padx=(0, 10))

        clear_btn = ttk.Button(btn_frame, text="Tozalash", command=self._clear)
        clear_btn.pack(side=tk.LEFT, padx=(0, 10))

        # Natijalar
        result_frame = ttk.LabelFrame(main_frame, text="Natijalar", padding="10")
        result_frame.pack(fill=tk.BOTH, expand=True)

        self.result_text = scrolledtext.ScrolledText(
            result_frame,
            wrap=tk.WORD,
            font=('Consolas', 10),
            height=15
        )
        self.result_text.pack(fill=tk.BOTH, expand=True)

        # Scrollbar
        scrollbar = ttk.Scrollbar(result_frame, orient=tk.VERTICAL, command=self.result_text.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.result_text.configure(yscrollcommand=scrollbar.set)

    def _browse_source(self):
        """Manba faylni tanlash"""
        filetypes = [
            ("Barcha qo'llab-quvvatlanadigan fayllar", "*.json *.zip"),
            ("JSON fayllar", "*.json"),
            ("ZIP arxivlar", "*.zip"),
            ("Barcha fayllar", "*.*")
        ]

        path = filedialog.askopenfilename(
            title="Manba faylni tanlang",
            filetypes=filetypes
        )

        if path:
            self.source_path.set(path)

    def _detect_json(self):
        """Joriy papkadagi birinchi JSON faylni topish"""
        current_dir = os.getcwd()
        json_files = [f for f in os.listdir(current_dir) if f.endswith('.json')]

        if json_files:
            self.source_path.set(os.path.join(current_dir, json_files[0]))
            self._log(f"Topildi: {json_files[0]}")
        else:
            messagebox.showwarning("Ogohlantirish", "Joriy papkada JSON fayl topilmadi!")

    def _run_analysis(self):
        """Tahlilni ishga tushirish"""
        source = self.source_path.get().strip()

        if not source:
            messagebox.showerror("Xato", "Iltimos, manba faylni tanlang!")
            return

        if not os.path.exists(source):
            messagebox.showerror("Xato", f"Manba topilmadi: {source}")
            return

        # Tugmani o'chirish
        self.run_btn.configure(state='disabled')
        self.status_var.set("Tahlil boshlandi...")
        self.progress_var.set(0)
        self.result_text.delete(1.0, tk.END)

        # Tahlilni alohida thread'da ishga tushirish
        thread = threading.Thread(target=self._analysis_worker, args=(source,))
        thread.daemon = True
        thread.start()

    def _analysis_worker(self, source):
        """Tahlil worker thread"""
        try:
            self._log(f"Manba: {source}")
            self._log("Fayllar skanerlanmoqda...")
            self.progress_var.set(20)

            # Fayllarni skanerlash
            files = self.extractor.scanner.scan_source(source)
            self._log(f"Topildi: {len(files)} ta fayl")
            self.progress_var.set(40)

            # Filtrlash
            extensions = [e.strip() for e in self.extensions_var.get().split(',') if e.strip()]
            if extensions:
                files = [f for f in files if any(f.get('path', '').endswith(ext) for ext in extensions)]

            folder = self.folder_var.get().strip()
            if folder:
                files = self.extractor.scanner.filter_by_folder(files, folder)

            self._log(f"Filtrlangan: {len(files)} ta fayl")
            self.progress_var.set(50)

            # Tahlil
            self._log("Fayllar tahlil qilinmoqda...")
            analyzed = self.extractor.analyzer.analyze_files(files)
            self.progress_var.set(70)

            # Modullar
            modules = {}
            if self.modules_var.get():
                self._log("Modullar tahlil qilinmoqda...")
                modules = self.extractor.module_analyzer.analyze_modules(analyzed)

            # Resurslar
            resources = {}
            if self.resources_var.get():
                self._log("Resurslar tahlil qilinmoqda...")
                resources = self.extractor.resource_analyzer.analyze_resources(analyzed)

            self.progress_var.set(85)

            # Hisobotlar
            formats = [fmt for fmt, var in self.format_vars.items() if var.get()]
            self._log(f"Hisobotlar yaratilmoqda: {formats}")

            generated = self.extractor.reporter.generate_all_reports(
                analyzed, modules, resources, formats
            )

            self.progress_var.set(100)

            # Natijalarni ko'rsatish
            self._log("\n" + "=" * 50)
            self._log("TAHLIL YAKUNLANDI!")
            self._log("=" * 50)
            self._log(f"Jami fayllar: {len(analyzed)}")
            self._log(f"Jami qatorlar: {sum(f.get('lines', 0) for f in analyzed):,}")
            self._log(f"Modullar: {len(modules)}")
            self._log("\nYaratilgan hisobotlar:")
            for path in generated:
                self._log(f"  - {path}")

            self.status_var.set("Tayyor")

        except Exception as e:
            self._log(f"\nXATOLIK: {str(e)}")
            self.status_var.set("Xatolik yuz berdi")
        finally:
            self.run_btn.configure(state='normal')

    def _log(self, message):
        """Xabarni logga yozish"""
        self.result_text.insert(tk.END, message + "\n")
        self.result_text.see(tk.END)
        self.root.update_idletasks()

    def _clear(self):
        """Tozalash"""
        self.source_path.set("")
        self.result_text.delete(1.0, tk.END)
        self.progress_var.set(0)
        self.status_var.set("Tayyor")

    def run(self):
        """GUI ni ishga tushirish"""
        self.root.mainloop()
